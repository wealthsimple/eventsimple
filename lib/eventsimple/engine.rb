require 'rails'

module Eventsimple
  class Engine < ::Rails::Engine
    isolate_namespace Eventsimple

    module PostgresXid8Extension
      def load_additional_types(oids=nil)
        type_map.alias_type 'xid8', 'string'
        super
      end
    end



    config.generators do |g|
      g.test_framework :rspec
      g.helper false
      g.view_specs false
    end

    config.after_initialize do
      require 'eventsimple/reactor'
      require 'eventsimple/outbox/models/cursor'

      # ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend PostgresXid8Extension

      verify_dispatchers!

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

    def verify_dispatchers!
      unless Eventsimple.configuration.dispatchers.all? { |dispatcher|
        dispatcher < Eventsimple::Dispatcher
      }
        raise ArgumentError, 'dispatchers must inherit from Eventsimple::Dispatcher'
      end
    end
  end
end
