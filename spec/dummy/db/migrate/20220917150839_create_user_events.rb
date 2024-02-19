class CreateUserEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :user_events do |t|
      t.string :aggregate_id, null: false, index: true
      t.string :idempotency_key, null: true
      t.string :type, null: false
      t.json :data, null: false, default: {}
      t.json :metadata, null: false, default: {}

      t.datetime :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }

      t.index :idempotency_key, unique: true

      # temporary to enable backfill
      t.integer :eventide_position_id
      t.index :eventide_position_id, unique: true
    end
  end
end
