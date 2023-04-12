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
    end
  end
end
