class CreateTopics < ActiveRecord::Migration[7.2]
  def change
    create_table :topics do |t|
      t.text :content, null: false
      t.timestamps
    end
  end
end
