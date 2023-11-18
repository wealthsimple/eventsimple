# frozen_string_literal: true

module UserComponent
  module Events
    class OverrideTimestamp < UserEvent
      attribute :data, Eventsimple::DataType.new(self)

      class Message < Eventsimple::Message
        attribute :canonical_id, DryTypes::Strict::String
        attribute :created_at, DryTypes::JSON::Time
        attribute :updated_at, DryTypes::JSON::Time
      end

      def apply(user)
        user.canonical_id = data.canonical_id
        user.created_at = data.created_at
        user.updated_at = data.updated_at
      end
    end
  end
end
