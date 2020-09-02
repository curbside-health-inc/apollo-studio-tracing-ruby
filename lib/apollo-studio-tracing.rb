# frozen_string_literal: true

require 'apollo-studio-tracing/tracing/proto'
require 'apollo-studio-tracing/tracing/node_map'
require 'apollo-studio-tracing/tracing/tracer'
require 'apollo-studio-tracing/tracing'

module ApolloStudioTracing
  extend self

  attr_accessor :logger

  # TODO: Initialize this to Rails.logger in a Railtie
  self.logger = Logger.new(STDOUT)

  def use(schema, **options)
    tracer = ApolloStudioTracing::Tracer.new(**options)
    # TODO: Shutdown tracers when reloading code in Rails
    # (although it's unlikely you'll have Apollo Tracing enabled in development)
    tracers << tracer
    schema.tracer(tracer)
    tracer.start_trace_channel
  end

  def flush
    tracers.each(&:flush_trace_channel)
  end

  def shutdown
    tracers.each(&:shutdown_trace_channel)
  end

  trap('SIGINT') do
    Thread.new { shutdown }
  end

  private

  def tracers
    @tracers ||= []
  end
end
