class CreateBackgroundLists < ActiveRecord::Migration[7.2]
  def change
    create_table :background_lists do |t|
      t.references :user, foreign_key: true, null: false
      t.references :image, foreign_key: { to_table: :background_images }, null: false
      t.timestamps
    end
  end
end
