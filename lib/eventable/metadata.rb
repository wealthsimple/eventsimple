# frozen_string_literal: true

# Event metadata store information on the event, for example the user who triggered the event.
module Eventable
  class Metadata < Eventable::Message
    schema schema.strict

    attribute? :actor_id, DryTypes::Strict::String
    attribute? :reason, DryTypes::Strict::String
  end
end
