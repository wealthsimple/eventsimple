# frozen_string_literal: true

class CreateEventsimpleOutboxCursor < ActiveRecord::Migration[7.1]
  def change
    create_table :eventsimple_outbox_cursors do |t|
      t.string :identifier, null: false
      t.bigint :cursor, null: false

      t.index [:identifier], unique: true
    end
  end
end
