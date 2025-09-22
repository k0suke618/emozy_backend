class CreateIconImageLists < ActiveRecord::Migration[7.2]
  def change
    create_table :icon_image_lists do |t|
      t.references :user, foreign_key: true, null: false
      t.references :image, foreign_key: { to_table: :icon_images }, null: false
      t.timestamps
    end
  end
end
