class UserEvent < ApplicationRecord
  extend Eventable::Event

  drives_events_for User, aggregate_id: :canonical_id, events_namespace: 'UserComponent::Events'
end
