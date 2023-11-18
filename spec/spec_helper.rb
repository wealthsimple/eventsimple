# frozen_string_literal: true

require 'eventsimple'
require 'eventsimple/support/spec_helpers'

require 'retriable'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  require File.expand_path('../spec/dummy/config/environment.rb', __dir__)
  ENV['RAILS_ROOT'] ||= "#{File.dirname(__FILE__)}../../../spec/dummy"

  require 'rspec/rails'

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
end
