# frozen_string_literal: true

module UserComponent
  module Events
    class Updated < UserEvent
      attribute :data, Eventable::DataType.new(self)

      class Message < Eventable::Message
        attribute :email, DryTypes::Strict::String.optional
      end

      def can_apply?(user)
        user.deleted_at.nil?
      end

      def apply(user)
        user.email = data.email
        user
      end
    end
  end
end
