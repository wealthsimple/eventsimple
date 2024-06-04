# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../spec/dummy/config/environment.rb', __dir__)
ENV['RAILS_ROOT'] ||= "#{File.dirname(__FILE__)}../../../spec/dummy"

require 'pry'
require 'eventsimple'
require 'eventsimple/support/spec_helpers'
require 'retriable'
require 'rspec/rails'

RSpec.configure do |config|

  # Enable Packwerk factories
  config.before do
    allow(Germinator::Environment).to receive(:enabled?).and_return(true)
    Germinator.init
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.use_transactional_fixtures = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.order = :random

  Kernel.srand config.seed

  ActiveRecord::Migration.maintain_test_schema!

  Retriable.configure do |c|
    c.tries = 1
    c.rand_factor = 0.0
    c.base_interval = 0

    c.contexts.each_key do |context|
      c.contexts[context][:tries] = 1
      c.contexts[context][:base_interval] = 0
    end
  end

  FactoryBot.define do
    after(:build) { |model| model.enable_writes! if model.class.ancestors.include? Eventsimple::Entity::InstanceMethods }
  end

  config.include FactoryBot::Syntax::Methods
end
