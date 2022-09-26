class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :canonical_id, null: false

      t.integer :lock_version
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
