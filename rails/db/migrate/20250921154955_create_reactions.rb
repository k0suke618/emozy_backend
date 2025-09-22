class CreateReactions < ActiveRecord::Migration[7.2]
  def change
    create_table :reactions do |t|
      t.string :image, null: false
      t.timestamps
    end
  end
end
