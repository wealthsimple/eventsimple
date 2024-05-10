# frozen_string_literal: true

module Eventsimple
  module Outbox
    class Cursor < Eventsimple.configuration.parent_record_klass
      self.table_name = 'eventsimple_outbox_cursors'

      def self.fetch(identifier)
        existing = find_by(identifier: identifier)
        existing ? existing.cursor : 0
      end

      def self.set(identifier, cursor)
        upsert(
          {
            identifier: identifier,
            cursor: cursor,
          },
          unique_by: [:identifier],
        )
      end
    end
  end
end
