# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"
require 'ws/gem_publisher/tasks'

APP_RAKEFILE = File.expand_path('spec/dummy/Rakefile', __dir__)
load 'rails/tasks/engine.rake'

RuboCop::RakeTask.new

task default: %i[spec rubocop]
