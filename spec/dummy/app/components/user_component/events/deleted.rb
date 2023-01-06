# frozen_string_literal: true

module UserComponent
  module Events
    class Deleted < UserEvent
      def can_apply?(user)
        user.persisted? && user.deleted_at.nil?
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
