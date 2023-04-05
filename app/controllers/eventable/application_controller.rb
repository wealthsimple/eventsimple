module Eventable
  class ApplicationController < ActionController::Base
    helper_method :event_class_names

    def event_class_names
      @event_class_names ||= event_classes.map(&:name)
    end

    def event_classes
      Rails.application.eager_load!

      @event_classes ||= application_record_klass.descendants.filter { |d|
        d.ancestors.include? Eventable::Entity::InstanceMethods
      }
    end

    private

    def application_record_klass
      ApplicationRecord if Eventable.configuration.namespace.blank?

      "#{Eventable.configuration.namespace}::ApplicationRecord".constantize
    end
  end
end
