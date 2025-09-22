class CreateIconImageLists < ActiveRecord::Migration[7.2]
  def change
    create_table :icon_image_lists do |t|
      t.timestamps
    end
  end
end
