# frozen_string_literal: true

module UserComponent
  module Events
    class Broken < UserEvent
      def apply(user)
        # this event is for testing the broken async reactor
        user
      end
    end
  end
end
