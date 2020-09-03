# frozen_string_literal: true

# module ApolloStudioTracing
#   module Tracing
#     KEY = :ftv1
#     DEBUG_KEY = "#{KEY}_debug".to_sym
#     class NotInstalledError < StandardError
#       MESSAGE = 'Apollo Studio Tracing not installed. \
# Add `use ApolloStudioTracing::Tracing` to your schema.'

#       def message
#         MESSAGE
#       end
#     end

#     module_function

#     # TODO: (lsanwick) Remove in favor of top level `use`
#     # def use(schema)
#     #   schema.tracer ApolloStudioTracing::Tracing::Tracer
#     # end

#     # def should_add_traces(headers)
#     #   headers && headers['apollo-studio-tracing-include-trace'] == KEY.to_s
#     # end

#     # TODO: (lsanwick) Remove, this is unneeded if this module reports traces directly.
#     def attach_trace_to_result(result)
#       # return result unless result.context[:tracing_enabled]

#       trace = result.context.namespace(KEY)
#       # TODO: If there are errors during query validation, that could also cause a missing
#       # start_time
#       raise NotInstalledError unless trace[:start_time]

#       result['errors']&.each do |error|
#         trace[:node_map].add_error(error)
#       end

#       proto = ApolloStudioTracing::Tracing::Trace.new(
#         start_time: to_proto_timestamp(trace[:start_time]),
#         end_time: to_proto_timestamp(trace[:end_time]),
#         duration_ns: trace[:end_time_nanos] - trace[:start_time_nanos],
#         root: trace[:node_map].root,
#       )

#       result[:extensions] ||= {}
#       result[:extensions][KEY] = Base64.encode64(proto.class.encode(proto))

#       if result.context[:debug_tracing]
#         result[:extensions][DEBUG_KEY] = proto.to_h
#       end

#       result.to_h
#     end

#     def to_proto_timestamp(time)
#       Google::Protobuf::Timestamp.new(seconds: time.to_i, nanos: time.nsec)
#     end
#   end
# end
