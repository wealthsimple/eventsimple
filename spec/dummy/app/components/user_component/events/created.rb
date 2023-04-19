# frozen_string_literal: true

module UserComponent
  module Events
    class Created < UserEvent
      attribute :data, Eventsimple::DataType.new(self)

      class Message < Eventsimple::Message
        attribute :canonical_id, DryTypes::Strict::String
        attribute :username, DryTypes::Strict::String
        attribute :email, DryTypes::Strict::String.optional
      end

      def can_apply?(user)
        user.new_record?
      end

      def apply(user)
        user.canonical_id = data.canonical_id
        user.username = data.username
        user.email = data.email
        user
      end
    end
  end
end
