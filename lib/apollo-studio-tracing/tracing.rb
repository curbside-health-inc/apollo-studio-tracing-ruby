# frozen_string_literal: true

module ApolloStudioTracing
  # The module that gets mixed into a schema's trace class via `Schema.trace_with`.
  #
  # graphql-ruby builds one trace instance per query/multiplex, so this module only
  # holds a reference to the (long lived) tracer and forwards the hooks to it.
  #
  # See https://graphql-ruby.org/queries/tracing.html
  module Tracing
    def initialize(apollo_tracer: nil, **rest)
      @apollo_tracer = apollo_tracer
      super(**rest)
    end

    def execute_multiplex(multiplex:)
      return super unless @apollo_tracer

      @apollo_tracer.execute_multiplex(multiplex) { super }
    end

    def execute_query_lazy(query:, multiplex:)
      return super unless @apollo_tracer

      @apollo_tracer.execute_query_lazy(query, multiplex) { super }
    end

    def execute_field(field:, query:, ast_node:, arguments:, object:)
      return super unless @apollo_tracer

      @apollo_tracer.execute_field(field, query) { super }
    end

    def execute_field_lazy(field:, query:, ast_node:, arguments:, object:)
      return super unless @apollo_tracer

      @apollo_tracer.execute_field_lazy(field, query) { super }
    end
  end
end
