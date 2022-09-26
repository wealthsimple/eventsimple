# frozen_string_literal: true

module UserComponent
  module Events
    class Deleted < UserEvent
      def can_apply?(user)
        user.persisted?
      end

      def apply(user)
        user.deleted_at = created_at

        user.created_at ||= created_at
        user.updated_at = created_at

        user
      end
    end
  end
end
