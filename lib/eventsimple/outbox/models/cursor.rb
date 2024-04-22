# frozen_string_literal: true

module Eventsimple
  module Outbox
    class Cursor < Eventsimple.configuration.parent_record_klass
      self.table_name = 'eventsimple_outbox_cursors'

      def self.fetch(identifier, group_number: 0)
        existing = find_by(identifier: identifier.to_s, group_number: group_number)
        existing ? existing.cursor : 0
      end

      def self.set(identifier, cursor, group_number: 0)
        upsert(
          {
            identifier: identifier.to_s,
            group_number: group_number,
            cursor: cursor,
          },
          unique_by: [:identifier, :group_number],
        )
      end
    end
  end
end
