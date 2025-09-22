class CreateFrameLists < ActiveRecord::Migration[7.2]
  def change
    create_table :frame_lists do |t|
      t.references :user, foreign_key: true, null: false
      t.references :image, foreign_key: { to_table: :frame_images }, null: false
      t.timestamps
    end
  end
end
