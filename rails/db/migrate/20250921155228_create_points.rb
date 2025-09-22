class CreatePoints < ActiveRecord::Migration[7.2]
  def change
    create_table :points do |t|
      t.references :point_type, foreign_key: true, null: false
      t.bigint :value, null: false
      t.timestamps
    end
  end
end
