# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require 'pry'
require 'bundler/setup'
require 'ws/gem_publisher/support/spec_helper'
# require 'eventable'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expose_dsl_globally = false

  config.exclude_pattern = 'spec/dummy/**/*.rb'

  # Run just filtered tests, or all tests
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def mock_rails!
  before do
    FileUtils.cp('./spec/eventable/initializers/secrets.yml', './config/')
    require_relative 'mock_rails'
  end

  after do
    FileUtils.rm('./config/secrets.yml')
  end
end
