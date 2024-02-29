# frozen_string_literal: true

# Event metadata store information on the event, for example the user who triggered the event.
module Eventsimple
  class Metadata < Eventsimple::Message
    schema schema.strict

    attribute? :actor_id, DryTypes::Strict::String.optional
    attribute? :reason, DryTypes::Strict::String.optional
  end
end
