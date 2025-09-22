class CreateTopics < ActiveRecord::Migration[7.2]
  def change
    create_table :topics do |t|
      t.text :topic, null: false
      t.timestamps
    end
  end
end
