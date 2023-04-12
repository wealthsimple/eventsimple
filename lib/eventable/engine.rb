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
      Eventable.configuration.dispatchers.map(&:constantize)
    end
  end
end
