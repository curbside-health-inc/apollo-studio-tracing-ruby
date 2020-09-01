# apollo-studio-tracing

[![CircleCI](https://circleci.com/gh/EnjoyTech/apollo-studio-tracing-ruby/tree/master.svg?style=svg)](https://circleci.com/gh/EnjoyTech/apollo-studio-tracing-ruby/tree/master)

This gem extends the [GraphQL Ruby](http://graphql-ruby.org/) gem to add support for sending trace data to [Apollo Studio](https://www.apollographql.com/docs/studio/). It is intended to be a full-featured replacement for the unmaintained [apollo-tracing-ruby](https://github.com/uniiverse/apollo-tracing-ruby) gem, and it is built HEAVILY from the work done within the Gusto [apollo-federation-ruby](https://github.com/Gusto/apollo-federation-ruby) gem.

## DISCLAIMER

This gem is still in a beta stage and may have some bugs or incompatibilities. See the [Known Issues and Limitations](#known-issues-and-limitations) below. If you run into any problems, please [file an issue](https://github.com/EnjoyTech/apollo-studio-tracing-ruby/issues).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'apollo-studio-tracing'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install apollo-studio-tracing

## Getting Started

1. Add `use ApolloStudioTracing::Tracing` to your schema class.
2. Change your controller to add `tracing_enabled: true` to the execution context based on the presence of the "include trace" header:
   ```ruby
   def execute
     # ...
     context = {
       tracing_enabled: ApolloStudioTracing::Tracing.should_add_traces(headers)
     }
     # ...
   end
   ```
3. Change your controller to attach the traces to the response:
   ```ruby
   def execute
     # ...
     result = YourSchema.execute(query, ...)
     render json: ApolloStudioTracing::Tracing.attach_trace_to_result(result)
   end
   ```

## Known Issues and Limitations

- Only works with class-based schemas, the legacy `.define` API will not be supported

## Maintainers

- [Luke Sanwick](https://github.com/lsanwick)
