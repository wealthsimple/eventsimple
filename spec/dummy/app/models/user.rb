class User < ApplicationRecord
  extend Eventsimple::Entity

  event_driven_by UserEvent, aggregate_id: :canonical_id, filter_attributes: [:username, :email]
end
