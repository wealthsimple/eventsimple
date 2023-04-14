require 'rails'

module Eventable
  class Engine < ::Rails::Engine
    isolate_namespace Eventable

    config.generators do |g|
      g.test_framework :rspec
      g.helper false
      g.view_specs false
    end

    config.after_initialize do
      dispatchers = Eventable.configuration.dispatchers.map(&:constantize)

      unless dispatchers.all? { |dispatcher| dispatcher.superclass == Eventable::Dispatcher }
        raise ArgumentError, 'dispatchers must inherit from Eventable::Dispatcher'
      end

      retry_intervals = Array.new(Eventable.configuration.max_concurrency_retries) { 0 }

      Retriable.configure do |c|
        c.contexts[:reactor] = {
          tries: 7,
          base_interval: 1.0,
          multiplier: 1.0,
          rand_factor: 0.0,
          on: ActiveRecord::RecordNotFound,
        }
        c.contexts[:optimistic_locking] = {
          intervals: retry_intervals,
          on: ActiveRecord::StaleObjectError,
        }
      end
    end
  end
end
