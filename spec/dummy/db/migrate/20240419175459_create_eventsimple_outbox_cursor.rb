# frozen_string_literal: true

class CreateEventsimpleOutboxCursor < ActiveRecord::Migration[7.1]
  def change
    create_table :eventsimple_outbox_cursors do |t|
      t.string :identifier, null: false
      t.integer :group_number, null: false
      t.bigint :cursor, null: false

      t.index [:identifier, :group_number], unique: true,
        name: 'index_eventsimple_outbox_cursors_event_klass_group_number'
    end
  end
end
