# frozen_string_literal: true

class User < ApplicationRecord
  extend Eventsimple::Entity

  event_driven_by UserEvent, aggregate_id: :canonical_id, filter_attributes: %i[username email]
end
