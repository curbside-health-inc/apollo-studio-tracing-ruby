# frozen_string_literal: true

require 'apollo-studio-tracing/proto'
require 'apollo-studio-tracing/node_map'
require 'apollo-studio-tracing/tracer'

module ApolloStudioTracing
  extend self

  KEY = :apollo_trace
  DEBUG_KEY = "#{KEY}_debug".to_sym

  class NotInstalledError < StandardError
    MESSAGE = 'Apollo Studio Tracing not installed. \
Add `use ApolloStudioTracing::Tracing` to your schema.'

    def message
      MESSAGE
    end
  end



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
