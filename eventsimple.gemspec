# frozen_string_literal: true

require_relative "lib/eventsimple/version"

Gem::Specification.new do |spec|
  spec.name = 'eventsimple'
  spec.version = Eventsimple::VERSION
  spec.authors = ['Zulfiqar Ali']
  spec.email = ['zulfiqar@wealthsimple.com']

  spec.summary = 'Event sourcing toolkit using Rails and ActiveJob'
  spec.description = 'Event sourcing toolkit using Rails and ActiveJob'
  spec.homepage = 'https://github.com/wealthsimple/eventsimple'
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata['changelog_uri'] = "https://github.com/wealthsimple/eventsimple/blob/main/CHANGELOG.md"
  spec.license = 'MIT'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git))})
    end
  end
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'dry-struct', '~> 1.6'
  spec.add_runtime_dependency 'dry-types', '~> 1.7'
  spec.add_runtime_dependency 'pg', '~> 1.4'
  spec.add_runtime_dependency 'rails', '~> 7.0'
  spec.add_runtime_dependency 'retriable', '~> 3.1'

  spec.add_development_dependency 'bundle-audit'
  spec.add_development_dependency 'fuubar'
  spec.add_development_dependency 'git'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'parse_a_changelog'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'ws-style'
end
