# frozen_string_literal: true

require 'socket'

require 'apollo-studio-tracing/version'
require 'apollo-studio-tracing/trace_channel'

# Trace events are nested and fire in this order
# for a simple single-field query like `{ foo }`:
#
# <execute_multiplex>
#   <lex></lex>
#   <parse></parse>
#   <validate></validate>
#   <analyze_multiplex>
#     <analyze_query></analyze_query>
#   </analyze_multiplex>
#
#   <execute_query>
#     <execute_field></execute_field>
#   </execute_query>
#
#   <execute_query_lazy>
#
#     # `execute_field_lazy` fires *only* when the field is lazy
#     # (https://graphql-ruby.org/schema/lazy_execution.html)
#     # so if it fires we should overwrite the ending times recorded
#     # in `execute_field` to capture the total execution time.
#
#     <execute_field_lazy></execute_field_lazy>
#
#   </execute_query_lazy>
#
#   # `execute_query_lazy` *always* fires, so it's a
#   # safe place to capture ending times of the full query.
#
# </execute_multiplex>

module ApolloStudioTracing
  # rubocop:disable Metrics/ClassLength
  class Tracer
    attr_reader :trace_prepare, :query_signature

    def initialize(
      graph_ref: nil,
      executable_schema_id: nil,
      service_version: nil,
      trace_prepare: nil,
      query_signature: nil,
      api_key: nil,
      **trace_channel_options
    )
      @trace_prepare = trace_prepare || proc {}
      # TODO: This should be smarter
      # TODO (lsanwick) Replace with reference implementation from
      # https://github.com/apollographql/apollo-tooling/blob/master/packages/apollo-graphql/src/operationId.ts
      @query_signature = query_signature || proc(&:query_string)

      report_header = ApolloStudioTracing::ReportHeader.new(
        hostname: hostname,
        agent_version: agent_version,
        service_version: service_version,
        runtime_version: RUBY_DESCRIPTION,
        uname: uname,
        graph_ref: graph_ref || ENV.fetch('ENGINE_SCHEMA_TAG', 'current'),
        executable_schema_id: executable_schema_id,
      )
      @trace_channel = ApolloStudioTracing::TraceChannel.new(
        report_header: report_header,
        api_key: api_key,
        **trace_channel_options,
      )
    end

    def start_trace_channel
      @trace_channel.start
    end

    def shutdown_trace_channel
      @trace_channel.shutdown
    end

    def flush_trace_channel
      @trace_channel.flush
    end

    def tracing_enabled?(context)
      context && context[:apollo_tracing_enabled]
    end

    def execute_multiplex(multiplex)
      # Step 1:
      # Create a trace hash on each query's context and record start times.
      multiplex.queries.each { |query| start_trace(query) }

      results = yield

      # Step 5
      #  Enqueue the final trace onto the TraceChannel.
      results.map { |result| attach_trace_to_result(result) }
    end

    def start_trace(query)
      return unless tracing_enabled?(query&.context)

      query.context.namespace(ApolloStudioTracing::KEY).merge!(
        start_time: Time.now.utc,
        start_time_nanos: Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond),
        node_map: NodeMap.new,
      )
    end

    # Step 2:
    # * Record start and end times for the field resolver.
    # * Rescue errors so the method doesn't exit early.
    # * Create a trace "node" and attach field details.
    # * Propagate the error (if necessary) so it ends up in the top-level errors array.
    #
    # Nodes are added the NodeMap stored in the trace hash.
    #
    # Errors are added to nodes in `ApolloStudioTracing::Tracer#attach_trace_to_result`
    # because we don't have the error `location` here.
    def execute_field(field, query)
      context = query.context
      return yield unless tracing_enabled?(context)

      start_time_nanos = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)

      begin
        result = yield
      rescue StandardError => e
        error = e
      end

      end_time_nanos = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)

      path = context[:current_path]
      field_name = field.graphql_name

      trace = context.namespace(ApolloStudioTracing::KEY)
      node = trace[:node_map].add(path)

      # original_field_name is set only for aliased fields
      node.original_field_name = field_name if field_name != path.last
      node.type = field.type.to_type_signature
      node.parent_type = field.owner.graphql_name
      node.start_time = start_time_nanos - trace[:start_time_nanos]
      node.end_time = end_time_nanos - trace[:start_time_nanos]

      raise error if error

      result
    end

    # Optional Step 3:
    # Overwrite the end times on the trace node if the resolver was lazy.
    def execute_field_lazy(field, query)
      context = query.context
      return yield unless tracing_enabled?(context)

      begin
        result = yield
      rescue StandardError => e
        error = e
      end

      end_time_nanos = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)

      path = context[:current_path]
      trace = context.namespace(ApolloStudioTracing::KEY)

      # When a field is resolved with an array of lazy values, the runtime fires an
      # `execute_field` for the resolution of the field and then a `execute_field_lazy` event for
      # each lazy value in the array. Since the path here will contain an index (indicating which
      # lazy value we're executing: e.g. ['arrayOfLazies', 0]), we won't have a node for the path.
      # We only care about the end of the parent field (e.g. ['arrayOfLazies']), so we get the
      # node for that path. What ends up happening is we update the end_time for the parent node
      # for each of the lazy values. The last one that's executed becomes the final end time.
      if field.type.list? && path.last.is_a?(Integer)
        path = path[0...-1]
      end
      node = trace[:node_map].node_for_path(path)
      node.end_time = end_time_nanos - trace[:start_time_nanos]

      raise error if error

      result
    end

    # Step 4:
    # Record end times and merge them into the trace hash
    def execute_query_lazy(query, multiplex)
      result = yield

      # Normalize to an array of queries regardless of whether we are multiplexing or performing a
      # single query.
      queries = Array(multiplex&.queries || query)

      queries.map do |q|
        next unless tracing_enabled?(q&.context)

        trace = q.context.namespace(ApolloStudioTracing::KEY)

        trace.merge!(
          end_time: Time.now.utc,
          end_time_nanos: Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond),
        )
      end

      result
    end

    private

    def attach_trace_to_result(result)
      return result unless tracing_enabled?(result.context)

      trace = result.context.namespace(ApolloStudioTracing::KEY)

      result['errors']&.each do |error|
        trace[:node_map].add_error(error)
      end

      @trace_channel.queue(
        "# #{result.query.operation_name || '-'}\n#{query_signature.call(result.query)}",
        trace,
        result.context,
      )

      result
    end

    def hostname
      @hostname ||= Socket.gethostname
    end

    def agent_version
      @agent_version ||= "apollo-studio-tracing #{ApolloStudioTracing::VERSION}"
    end

    def uname
      @uname ||= `uname -a`
    end
  end
  # rubocop:enable Metrics/ClassLength
end
