# frozen_string_literal: true

module UserComponent
  module Events
    class RescuedInvalidTransitionWithReraise < UserEvent
      rescue_invalid_transition do |error|
        raise error
      end

      attribute :data, Eventable::DataType.new(self)

      class Message < Eventable::Message
        attribute :canonical_id, DryTypes::Strict::String
      end

      def can_apply?(user)
        user.new_record?
      end

      def apply(user)
        user.canonical_id = data.canonical_id
        user
      end
    end
  end
end
