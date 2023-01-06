module Eventable
  class ApplicationController < ActionController::Base
    before_action :load_event_classes

    private

    def load_event_classes
      # How can we do this better? Preferably without requiring an eager load.
      Dir[Rails.root.join('app', 'models', '*.rb')].sort.each { |f| require f }

      @event_classes = ApplicationRecord.descendants.filter { |d|
        d.ancestors.include? Eventable::Entity::InstanceMethods
      }.map(&:name)

      @model_name = nil
      @canonical_id = nil
    end
  end
end
