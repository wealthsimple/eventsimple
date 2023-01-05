module Eventable
  class HomeController < ApplicationController
    def index
      # How can we do this better? Preferably without requiring an eager load.
      Dir[Rails.root.join('app', 'models', '*.rb')].sort.each { |f| require f }

      @event_classes = ApplicationRecord.descendants.filter { |d|
        d.ancestors.include? Eventable::Entity::InstanceMethods
      }.map(&:name)
    end
  end
end
