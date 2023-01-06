class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :canonical_id, null: false

      t.string :username, null: false
      t.string :email

      t.integer :lock_version
      t.datetime :deleted_at
      t.timestamps

      t.index :canonical_id, unique: true
    end
  end
end
