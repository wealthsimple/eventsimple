module Eventable
  class ApplicationController < ActionController::Base
    helper ApplicationHelper

    before_action :load_event_classes

    private

    def load_event_classes
      Rails.application.eager_load!

      @event_classes = ApplicationRecord.descendants.filter { |d|
        d.ancestors.include? Eventable::Entity::InstanceMethods
      }.map(&:name)
    end
  end
end
