# frozen_string_literal: true

require_relative "lib/eventable/version"

Gem::Specification.new do |spec|
  spec.name = 'eventable'
  spec.version = Eventable::VERSION
  spec.authors = ['Zulfiqar Ali']
  spec.email = ['zulfiqar@wealthsimple.com']

  spec.summary = 'Event driven architecture using Rails and Sidekiq'
  spec.description = 'Event driven architecture using Rails and Sidekiq'
  spec.homepage = 'https://github.com/wealthsimple/eventable'
  spec.required_ruby_version = ">= 2.7.5"

  spec.metadata['allowed_push_host'] = "https://nexus.iad.w10external.com/repository/gems-private"
  spec.metadata['changelog_uri'] = "https://github.com/wealthsimple/eventable/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git))})
    end
  end
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'dry-struct'
  spec.add_runtime_dependency 'dry-types'
  spec.add_runtime_dependency 'pg'
  spec.add_runtime_dependency 'rails'
  spec.add_runtime_dependency 'retriable'
  spec.add_runtime_dependency 'sidekiq'

  spec.add_development_dependency 'bundle-audit'
  spec.add_development_dependency 'fuubar'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'ws-style'
end
