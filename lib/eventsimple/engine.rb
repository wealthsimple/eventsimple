require 'rails'

module Eventsimple
  class Engine < ::Rails::Engine
    isolate_namespace Eventsimple

    config.generators do |g|
      g.test_framework :rspec
      g.helper false
      g.view_specs false
    end

    config.after_initialize do
      dispatchers = Eventsimple.configuration.dispatchers.map(&:constantize)

      unless dispatchers.all? { |dispatcher| dispatcher.superclass == Eventsimple::Dispatcher }
        raise ArgumentError, 'dispatchers must inherit from Eventsimple::Dispatcher'
      end

      retry_intervals = Array.new(Eventsimple.configuration.max_concurrency_retries) { 0 }

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
