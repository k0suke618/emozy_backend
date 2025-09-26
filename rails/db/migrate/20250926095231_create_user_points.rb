class CreateUserPoints < ActiveRecord::Migration[7.2]
  def change
    create_table :user_points do |t|
      t.references :user, null: false, foreign_key: true
      t.references :point, null: false, foreign_key: true
      t.bigint :value, null: false
      t.timestamps
    end

    add_index :user_points, [:user_id, :point_id]
  end
end
