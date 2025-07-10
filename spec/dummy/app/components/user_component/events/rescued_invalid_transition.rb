# frozen_string_literal: true

module UserComponent
  module Events
    class RescuedInvalidTransition < UserEvent
      rescue_invalid_transition

      attribute :data, Eventsimple::DataType.new(self)

      class Message < Eventsimple::Message
        attribute :canonical_id, DryTypes::Strict::String
      end

      def can_apply?(user)
        user.new_record?
      end

      def apply(user)
        user.canonical_id = data.canonical_id
        user.username = 'test' #gitleaks:allow
        user.email = 'test@example.com'
      end
    end
  end
end
