# frozen_string_literal: true

module UserComponent
  module Events
    class RescuedInvalidTransition < UserEvent
      rescue_invalid_transition

      attribute :data, Eventable::DataType.new(self)

      class Message < Eventable::Message
        attribute :canonical_id, DryTypes::Strict::String
      end

      def can_apply?(user)
        user.new_record?
      end

      def apply(user)
        user.canonical_id = data.canonical_id
        user.username = 'test'
        user.email = 'test@example.com'
        user
      end
    end
  end
end
