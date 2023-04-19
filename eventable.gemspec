# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'eventable/version'

Gem::Specification.new do |spec|
  raise 'RubyGems 2+ is required to protect against public pushes' unless spec.respond_to? :metadata

  spec.name          = 'eventable'
  spec.version       = Eventable::VERSION
  spec.authors       = ['Zulfiqar Ali']
  spec.email         = ['zulfiqar@wealthsimple.com']

  spec.description   = 'Event driven architecture using Rails and Sidekiq'
  spec.summary       = 'Event driven architecture using Rails and Sidekiq'
  spec.homepage      = 'https://github.com/wealthsimple/eventable'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata['allowed_push_host'] = "https://nexus.iad.w10external.com/repository/gems-private"
  spec.metadata['changelog_uri'] = "https://github.com/wealthsimple/eventable/blob/main/CHANGELOG.md"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7.5'

  spec.add_runtime_dependency 'activerecord'
  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'dry-struct'
  spec.add_runtime_dependency 'dry-types'
  spec.add_runtime_dependency 'retriable'
  spec.add_runtime_dependency 'sidekiq'

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rails'
  spec.add_development_dependency 'fuubar'
end
