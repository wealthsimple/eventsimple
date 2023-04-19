class User < ApplicationRecord
  extend Eventsimple::Entity

  event_driven_by UserEvent, aggregate_id: :canonical_id
end
