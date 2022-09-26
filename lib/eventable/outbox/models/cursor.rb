# frozen_string_literal: true

module Eventable
  module Outbox
    class Cursor < ApplicationRecord
      self.table_name = 'eventable_outbox_cursors'

      def self.fetch(event_klass, group_number)
        existing = find_by(event_klass: event_klass.to_s, group_number: group_number)
        existing ? existing.cursor : 0
      end

      # rubocop:disable Rails/SkipsModelValidations
      def self.set(event_klass, group_number, cursor)
        upsert(
          {
            event_klass: event_klass.to_s,
            group_number: group_number,
            cursor: cursor,
          },
          unique_by: [:event_klass, :group_number],
        )
      end
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
