# frozen_string_literal: true

require 'spec_helper'
require 'apollo-studio-tracing'

module ApolloStudioTracing
  # Create a double of the API module that doesn't actually upload reports, but stashes them in an
  # array for inspection.
  class APIDouble
    @reports = []

    class << self
      attr_reader :reports

      def upload(report, _options)
        @reports << ApolloStudioTracing::Report.decode(report)
      end

      def traces
        @reports
          .map { |report| report.traces_per_query.values }
          .flatten
          .map(&:trace)
          .flatten
      end

      def clear_reports
        @reports = []
      end
    end
  end
end

RSpec.describe ApolloStudioTracing do
  RSpec.shared_examples 'a basic tracer' do
    let(:api) { ApolloStudioTracing::APIDouble }
    let(:report_header) do
      ApolloStudioTracing::ReportHeader.new(
        hostname: 'localhost',
        agent_version: '1',
        service_version: '1',
        runtime_version: '1',
        uname: 'test',
        graph_ref: 'test',
        executable_schema_id: 'test',
      )
    end
    let(:trace_channel) do
      ApolloStudioTracing::TraceChannel.new(report_header: report_header)
    end

    before do
      stub_const('ApolloStudioTracing::API', api)
      allow(ApolloStudioTracing::TraceChannel).to receive(:new).and_return(trace_channel)
      allow(trace_channel).to receive(:start).and_return(nil)
      allow(trace_channel).to receive(:flush).and_return(nil)
      allow(trace_channel).to receive(:shutdown).and_return(nil)
      original_queue = trace_channel.method(:queue)
      allow(trace_channel).to receive(:queue) do |query_key, trace, context|
        original_queue.call(query_key, trace, context)
        trace_channel.send(:drain_queue)
      end
    end

    after do
      api.clear_reports
    end

    # configure clocks to increment by 1 for each call
    before do
      t = Time.new(2019, 8, 4, 12, 0, 0, '+00:00')
      allow(Time).to receive(:now) { t += 1 }

      # nanos are used for durations and offsets, so you'll never see 42, 43, ...
      # instead, you'll see the difference from the first call (the start time)
      # which will be 1, 2, 3 ...
      ns = 42
      allow(Process).to receive(:clock_gettime)
        .with(Process::CLOCK_MONOTONIC, :nanosecond) { ns += 1 }
      allow(Process).to receive(:clock_gettime)
        .with(Process::CLOCK_MONOTONIC) { ns += 1 }
    end

    describe 'respecting options on context' do
      let(:schema) do
        query_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Query'

          field :test, String, null: false

          def test
            'hello world'
          end
        end

        Class.new(base_schema) do
          query query_obj
        end
      end

      it 'does not report to API by default' do
        schema.execute('{ test }')
        expect(api.reports).to be_empty
      end

      it 'reports to API when the context has apollo_tracing_enabled: true' do
        schema.execute('{ test }', context: { apollo_tracing_enabled: true })
        expect(api.reports).not_to be_empty
      end
    end

    def trace(query)
      schema.execute(query, context: { apollo_tracing_enabled: true })
      api.traces[0]
    end

    describe 'building the trace tree' do
      let(:schema) do
        grandchild_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Grandchild'

          field :id, String, null: false
        end

        child_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Child'

          field :id, String, null: false
          field :grandchild, grandchild_obj, null: false

          def grandchild
            { id: 'grandchild' }
          end
        end

        parent_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Parent'

          field :id, String, null: false
          field :child, child_obj, null: false

          def child
            { id: 'child' }
          end
        end

        query_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Query'

          field :parent, parent_obj, null: false
          field :strings, [String], null: false

          def parent
            { id: 'parent' }
          end

          def strings
            ['hello', 'goodbye']
          end
        end

        Class.new(base_schema) do
          query query_obj
        end
      end

      it 'records timing for children' do
        query = '{ parent { id, child { id, grandchild { id } } } }'
        expect(trace(query)).to eq(ApolloStudioTracing::Trace.new(
                                     start_time: { seconds: 1_564_920_001, nanos: 0 },
                                     end_time: { seconds: 1_564_920_002, nanos: 0 },
                                     duration_ns: 13,
                                     root: {
                                       child: [{
                                         response_name: 'parent',
                                         type: 'Parent!',
                                         start_time: 1,
                                         end_time: 2,
                                         parent_type: 'Query',
                                         child: [{
                                           response_name: 'id',
                                           type: 'String!',
                                           start_time: 3,
                                           end_time: 4,
                                           parent_type: 'Parent',
                                         }, {
                                           response_name: 'child',
                                           type: 'Child!',
                                           start_time: 5,
                                           end_time: 6,
                                           parent_type: 'Parent',
                                           child: [{
                                             response_name: 'id',
                                             type: 'String!',
                                             start_time: 7,
                                             end_time: 8,
                                             parent_type: 'Child',
                                           }, {
                                             response_name: 'grandchild',
                                             type: 'Grandchild!',
                                             start_time: 9,
                                             end_time: 10,
                                             parent_type: 'Child',
                                             child: [{
                                               response_name: 'id',
                                               type: 'String!',
                                               start_time: 11,
                                               end_time: 12,
                                               parent_type: 'Grandchild',
                                             }],
                                           },],
                                         },],
                                       }],
                                     },
                                   ))
      end

      it 'works for scalar arrays' do
        expect(trace('{ strings }')).to eq ApolloStudioTracing::Trace.new(
          start_time: { seconds: 1_564_920_001, nanos: 0 },
          end_time: { seconds: 1_564_920_002, nanos: 0 },
          duration_ns: 3,
          root: {
            child: [{
              response_name: 'strings',
              type: '[String!]!',
              start_time: 1,
              end_time: 2,
              parent_type: 'Query',
            }],
          },
        )
      end
    end

    class Lazy
      def initialize(value = 'lazy_value')
        @value = value
      end

      attr_reader :value
    end

    describe 'lazy values' do
      let(:schema) do
        item_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Item'

          field :id, String, null: false
        end

        query_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Query'

          field :lazy_scalar, String, null: false
          field :array_of_lazy_scalars, [String], null: false
          field :lazy_array_of_scalars, [String], null: false
          field :lazy_array_of_lazy_scalars, [String], null: false
          field :array_of_lazy_objects, [item_obj], null: false
          field :lazy_array_of_objects, [item_obj], null: false

          def lazy_scalar
            Lazy.new
          end

          def array_of_lazy_scalars
            [Lazy.new('hi'), Lazy.new('bye')]
          end

          def lazy_array_of_scalars
            Lazy.new(['hi', 'bye'])
          end

          def lazy_array_of_lazy_scalars
            Lazy.new([Lazy.new('hi'), Lazy.new('bye')])
          end

          def array_of_lazy_objects
            [Lazy.new(id: '123'), Lazy.new(id: '456')]
          end

          def lazy_array_of_objects
            Lazy.new([{ id: '123' }, { id: '456' }])
          end
        end

        Class.new(base_schema) do
          query query_obj
          lazy_resolve(Lazy, :value)
        end
      end

      it 'works with lazy values' do
        expect(trace('{ lazyScalar }')).to eq ApolloStudioTracing::Trace.new(
          start_time: { seconds: 1_564_920_001, nanos: 0 },
          end_time: { seconds: 1_564_920_002, nanos: 0 },
          duration_ns: 4,
          root: {
            child: [{
              response_name: 'lazyScalar',
              type: 'String!',
              start_time: 1,
              # This is the only discrepancy between a normal field and a lazy field.
              # The fake clock incremented once at the end of the `execute_field` step,
              # and again at the end of the `execute_field_lazy` step, so we record the
              # end time as being two nanoseconds after the start time instead of one.
              end_time: 3,
              parent_type: 'Query',
            }],
          },
        )
      end

      it 'works with an array of lazy scalars' do
        expect(trace('{ arrayOfLazyScalars }')).to eq ApolloStudioTracing::Trace.new(
          start_time: { seconds: 1_564_920_001, nanos: 0 },
          end_time: { seconds: 1_564_920_002, nanos: 0 },
          # The old runtime and the interpreter handle arrays of lazy objects differently.
          # The old runtime doesn't trigger the `execute_field_lazy` tracer event, so we have to
          # use the (inaccurate) end times from the `execute_field` event.
          duration_ns: schema.interpreter? ? 5 : 3,
          root: {
            child: [{
              response_name: 'arrayOfLazyScalars',
              type: '[String!]!',
              start_time: 1,
              end_time: schema.interpreter? ? 4 : 2,
              parent_type: 'Query',
            }],
          },
        )
      end

      it 'works with a lazy array of scalars' do
        expect(trace('{ lazyArrayOfScalars }')).to eq ApolloStudioTracing::Trace.new(
          start_time: { seconds: 1_564_920_001, nanos: 0 },
          end_time: { seconds: 1_564_920_002, nanos: 0 },
          duration_ns: 4,
          root: {
            child: [{
              response_name: 'lazyArrayOfScalars',
              type: '[String!]!',
              start_time: 1,
              end_time: 3,
              parent_type: 'Query',
            }],
          },
        )
      end

      it 'works with a lazy array of lazy scalars' do
        expect(trace('{ lazyArrayOfLazyScalars }')).to eq ApolloStudioTracing::Trace.new(
          start_time: { seconds: 1_564_920_001, nanos: 0 },
          end_time: { seconds: 1_564_920_002, nanos: 0 },
          duration_ns: schema.interpreter? ? 6 : 4,
          root: {
            child: [{
              response_name: 'lazyArrayOfLazyScalars',
              type: '[String!]!',
              start_time: 1,
              end_time: schema.interpreter? ? 5 : 3,
              parent_type: 'Query',
            }],
          },
        )
      end

      it 'works with array of lazy objects' do
        expect(trace('{ arrayOfLazyObjects { id } }')).to eq ApolloStudioTracing::Trace.new(
          start_time: { seconds: 1_564_920_001, nanos: 0 },
          end_time: { seconds: 1_564_920_002, nanos: 0 },
          duration_ns: schema.interpreter? ? 9 : 7,
          root: {
            child: [{
              response_name: 'arrayOfLazyObjects',
              type: '[Item!]!',
              start_time: 1,
              end_time: schema.interpreter? ? 6 : 2,
              parent_type: 'Query',
              child: [
                {
                  index: 0,
                  child: [{
                    response_name: 'id',
                    type: 'String!',
                    start_time: schema.interpreter? ? 4 : 3,
                    end_time: schema.interpreter? ? 5 : 4,
                    parent_type: 'Item',
                  }],
                },
                {
                  index: 1,
                  child: [{
                    response_name: 'id',
                    type: 'String!',
                    start_time: schema.interpreter? ? 7 : 5,
                    end_time: schema.interpreter? ? 8 : 6,
                    parent_type: 'Item',
                  }],
                },
              ],
            }],
          },
        )
      end

      it 'works with a lazy array of objects' do
        expect(trace('{ lazyArrayOfObjects { id } }')).to eq ApolloStudioTracing::Trace.new(
          start_time: { seconds: 1_564_920_001, nanos: 0 },
          end_time: { seconds: 1_564_920_002, nanos: 0 },
          duration_ns: 8,
          root: {
            child: [{
              response_name: 'lazyArrayOfObjects',
              type: '[Item!]!',
              start_time: 1,
              end_time: 3,
              parent_type: 'Query',
              child: [
                {
                  index: 0,
                  child: [{
                    response_name: 'id',
                    type: 'String!',
                    start_time: 4,
                    end_time: 5,
                    parent_type: 'Item',
                  }],
                },
                {
                  index: 1,
                  child: [{
                    response_name: 'id',
                    type: 'String!',
                    start_time: 6,
                    end_time: 7,
                    parent_type: 'Item',
                  }],
                },
              ],
            }],
          },
        )
      end

      it 'works with multiple lazy fields' do
        query = '{ lazyScalar arrayOfLazyScalars lazyArrayOfScalars }'
        expect(trace(query)).to eq ApolloStudioTracing::Trace.new(
          start_time: { seconds: 1_564_920_001, nanos: 0 },
          end_time: { seconds: 1_564_920_002, nanos: 0 },
          duration_ns: schema.interpreter? ? 11 : 9,
          root: {
            child: [{
              response_name: 'lazyScalar',
              type: 'String!',
              start_time: 1,
              end_time: 7,
              parent_type: 'Query',
            }, {
              response_name: 'arrayOfLazyScalars',
              type: '[String!]!',
              start_time: 3,
              end_time: schema.interpreter? ? 10 : 4,
              parent_type: 'Query',
            }, {
              response_name: 'lazyArrayOfScalars',
              type: '[String!]!',
              start_time: 5,
              end_time: 8,
              parent_type: 'Query',
            },],
          },
        )
      end
    end

    describe 'indices and errors' do
      let(:schema) do
        item_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Item'

          field :id, String, null: false
          field :name, String, null: false

          def name
            raise GraphQL::ExecutionError, "Can't continue with this query" if object[:id] == '2'

            "Item #{object[:id]}"
          end
        end

        query_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Query'

          field :items, [item_obj], null: false

          def items
            [{ id: '1' }, { id: '2' }]
          end
        end

        Class.new(base_schema) do
          query query_obj
        end
      end

      it 'records index instead of response_name for objects in arrays' do
        expect(trace('{ items { id, name } }')).to eq(
          ApolloStudioTracing::Trace.new(
            start_time: { seconds: 1_564_920_001, nanos: 0 },
            end_time: { seconds: 1_564_920_002, nanos: 0 },
            duration_ns: 11,
            root: {
              child: [{
                response_name: 'items',
                type: '[Item!]!',
                start_time: 1,
                end_time: 2,
                parent_type: 'Query',
                child: [
                  {
                    index: 0,
                    child: [{
                      response_name: 'id',
                      type: 'String!',
                      start_time: 3,
                      end_time: 4,
                      parent_type: 'Item',
                    }, {
                      response_name: 'name',
                      type: 'String!',
                      start_time: 5,
                      end_time: 6,
                      parent_type: 'Item',
                    },],
                  },
                  {
                    index: 1,
                    child: [{
                      response_name: 'id',
                      type: 'String!',
                      start_time: 7,
                      end_time: 8,
                      parent_type: 'Item',
                    }, {
                      response_name: 'name',
                      type: 'String!',
                      start_time: 9,
                      end_time: 10,
                      parent_type: 'Item',
                      error: [{
                        message: "Can't continue with this query",
                        location: [{ line: 1, column: 15 }],
                        json: {
                          message: "Can't continue with this query",
                          locations: [{ line: 1, column: 15 }], path: ['items', 1, 'name'],
                        }.to_json,
                      }],
                    },],
                  },
                ],
              }],
            },
          ),
        )
      end

      context 'when there is a parsing error' do
        it 'properly captures the error' do
          expect(trace('{ items { id, name }')).to eq(
            ApolloStudioTracing::Trace.new(
              start_time: { seconds: 1_564_920_001, nanos: 0 },
              end_time: { seconds: 1_564_920_002, nanos: 0 },
              duration_ns: 1,
              root: {
                child: [],
                error: [{
                  message: 'Unexpected end of document',
                  location: [],
                  json: {
                    message: 'Unexpected end of document',
                    locations: [],
                  }.to_json,
                }],
              },
            ),
          )
        end
      end

      context 'when there is a validation error' do
        it 'properly captures the error' do
          expect(trace('{ nonExistant }')).to eq(
            ApolloStudioTracing::Trace.new(
              start_time: { seconds: 1_564_920_001, nanos: 0 },
              end_time: { seconds: 1_564_920_002, nanos: 0 },
              duration_ns: 1,
              root: {
                child: [],
                error: [{
                  message: "Field 'nonExistant' doesn't exist on type 'Query'",
                  location: [{ line: 1, column: 3 }],
                  json: {
                    message: "Field 'nonExistant' doesn't exist on type 'Query'",
                    locations: [{ line: 1, column: 3 }],
                    path: ['query', 'nonExistant'],
                    extensions: {
                      code: 'undefinedField',
                      typeName: 'Query',
                      fieldName: 'nonExistant',
                    },
                  }.to_json,
                }],
              },
            ),
          )
        end
      end
    end
  end

  context 'with the legacy runtime' do
    let(:base_schema) do
      Class.new(GraphQL::Schema) do
        use ApolloStudioTracing
      end
    end

    it_behaves_like 'a basic tracer'
  end

  context 'with the new interpreter' do
    let(:base_schema) do
      Class.new(GraphQL::Schema) do
        use ApolloStudioTracing
        use GraphQL::Execution::Interpreter
        use GraphQL::Analysis::AST
      end
    end

    it_behaves_like 'a basic tracer'
  end

  context 'with enabled flag' do
    let(:report_header) do
      ApolloStudioTracing::ReportHeader.new(
        hostname: 'localhost',
        agent_version: '1',
        service_version: '1',
        runtime_version: '1',
        uname: 'test',
        graph_ref: 'test',
        executable_schema_id: 'test',
      )
    end
    let(:trace_channel) do
      ApolloStudioTracing::TraceChannel.new(report_header: report_header)
    end
    let(:schema) do
      query_obj = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'

        field :test, String, null: false

        def test
          'hello world'
        end
      end

      Class.new(base_schema) do
        query query_obj
      end
    end

    before do
      allow(ApolloStudioTracing::TraceChannel).to receive(:new).and_return(trace_channel)
    end

    context 'with no value' do
      let(:base_schema) do
        Class.new(GraphQL::Schema) do
          use ApolloStudioTracing
        end
      end

      it 'does starts up a trace channel' do
        schema.execute('{ test }')
        expect(ApolloStudioTracing::TraceChannel).to have_received(:new)
      end
    end

    context 'with a false value' do
      let(:base_schema) do
        Class.new(GraphQL::Schema) do
          use ApolloStudioTracing, enabled: false
        end
      end

      it 'does not start up a trace channel' do
        schema.execute('{ test }')
        expect(ApolloStudioTracing::TraceChannel).not_to have_received(:new)
      end
    end

    context 'with a true value' do
      let(:base_schema) do
        Class.new(GraphQL::Schema) do
          use ApolloStudioTracing, enabled: true
        end
      end

      it 'does start up a trace channel' do
        schema.execute('{ test }')
        expect(ApolloStudioTracing::TraceChannel).to have_received(:new)
      end
    end
  end
end
