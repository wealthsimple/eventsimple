require 'rails'

module Eventable
  class Engine < ::Rails::Engine
    isolate_namespace Eventable

    config.generators do |g|
      g.test_framework :rspec
      g.helper false
      g.view_specs false
    end
  end
end
