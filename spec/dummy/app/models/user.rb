class User < ApplicationRecord
  extend Eventable::Entity

  event_driven_by UserEvent
end
