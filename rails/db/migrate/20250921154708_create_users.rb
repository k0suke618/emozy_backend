class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false, index: { unique: true }
      t.text :profile, null: true
      t.bigint :point, null: false, default: 0
      t.references :icon, foreign_key: true, null: false, default: 1
      t.references :background, foreign_key: true, null: true
      t.references :frame, foreign_key: true, null: true

      t.string :encrypted_password, null: false, default: ""

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
