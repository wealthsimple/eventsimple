class User < ApplicationRecord
  extend Eventable::Entity

  event_driven_by UserEvent, aggregate_id: :canonical_id
end
