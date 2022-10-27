# frozen_string_literal: true

require 'ws/gem_publisher/support/spec_helper'

require 'eventable'
require 'eventable/support/spec_helpers'

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
  RSpec::Matchers.define_negated_matcher(:not_change, :change)

  ActiveRecord::Migration.maintain_test_schema!
end
