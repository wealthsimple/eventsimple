class UserEvent < ApplicationRecord
  extend Eventable::Event

  drives_events_for User, events_namespace: 'UserComponent::Events'
end
