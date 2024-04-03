# frozen_string_literal: true

module Eventsimple
  module Outbox
    class Cursor < Eventsimple.configuration.parent_record_klass
      self.table_name = 'eventsimple_outbox_cursors'

      def self.fetch(event_klass, group_number)
        existing = find_by(event_klass: event_klass.to_s, group_number: group_number)
        existing ? existing.cursor : 0
      end

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
    end
  end
end
