module Eventable
  class ApplicationController < ActionController::Base
    helper_method :event_class_names

    def event_class_names
      @event_class_names ||= event_classes.map(&:name)
    end

    def event_classes
      Rails.application.eager_load!

      @event_classes ||= ApplicationRecord.descendants.filter { |d|
        d.ancestors.include? Eventable::Entity::InstanceMethods
      }
    end
  end
end
