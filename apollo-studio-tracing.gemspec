# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'apollo-studio-tracing/version'

Gem::Specification.new do |spec|
  spec.name          = 'apollo-studio-tracing'
  spec.version       = ApolloStudioTracing::VERSION
  spec.authors       = ['Luke Saniwck']
  spec.email         = ['luke@enjoy.com']

  spec.summary       = 'A Ruby implementation of Apollo GraphQL Studio tracing'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/curbside-health-inc/apollo-studio-tracing-ruby'
  spec.license       = 'MIT'
  # graphql-ruby 2.x needs Ruby >= 2.7 and google-protobuf 4.x needs Ruby >= 3.1
  spec.required_ruby_version = '>= 3.1'

  spec.metadata    = {
    'homepage_uri' => 'https://github.com/curbside-health-inc/apollo-studio-tracing-ruby',
    'changelog_uri' => 'https://github.com/curbside-health-inc/apollo-studio-tracing-ruby/releases',
    'source_code_uri' => 'https://github.com/curbside-health-inc/apollo-studio-tracing-ruby',
    'bug_tracker_uri' => 'https://github.com/curbside-health-inc/apollo-studio-tracing-ruby/issues',
    'rubygems_mfa_required' => 'true',
  }

  spec.files = `git ls-files bin lib *.md LICENSE`.split("\n")

  # Module based traces (`Schema.trace_with` + `GraphQL::Tracing::Trace`), which replace the
  # deprecated `Schema.tracer` API, were introduced in graphql-ruby 2.1.0.
  spec.add_dependency 'graphql', '>= 2.1', '< 3'

  spec.add_dependency 'concurrent-ruby', '~> 1.2'
  # The generated protobuf stubs use `add_serialized_file`, which needs >= 3.25.
  spec.add_dependency 'google-protobuf', '>= 3.25', '< 5'

  spec.add_development_dependency 'actionpack', '>= 7.0'
  spec.add_development_dependency 'appraisal', '~> 2.5'
  spec.add_development_dependency 'debug', '>= 1.9'
  spec.add_development_dependency 'rack', '>= 2.2'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.6'
  spec.add_development_dependency 'rubocop', '~> 1.75'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.5'
end
