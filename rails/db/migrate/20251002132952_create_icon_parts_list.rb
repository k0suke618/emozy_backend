class CreateIconPartsList < ActiveRecord::Migration[7.2]
  def change
    create_table :icon_parts_lists do |t|
      # 保存したユーザーのID
      t.references :user, null: false, foreign_key: true
      # 選択したパーツのパスを保存するカラム
      t.string :eyes_image, null: false
      t.string :mouth_image, null: false
      t.string :skin_image, null: false
      t.string :front_hair_image, null: false
      t.string :back_hair_image, null: false
      t.string :eyebrows_image, null: false
      t.string :high_light_image, null: false
      t.string :clothing_image, null: false
      t.string :accessory_image, null: false
      t.timestamps
    end
  end
end
