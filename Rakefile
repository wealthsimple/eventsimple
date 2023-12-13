# frozen_string_literal: true

require "bundler/setup"

APP_RAKEFILE = File.expand_path('spec/dummy/Rakefile', __dir__)
Rake.load_rakefile 'spec/dummy/Rakefile'
load 'rails/tasks/engine.rake'

load 'rails/tasks/statistics.rake'

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]
