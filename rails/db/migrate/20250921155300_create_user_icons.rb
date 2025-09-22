class CreateUserIcons < ActiveRecord::Migration[7.2]
  def change
    create_table :user_icons do |t|
      t.references :user, foreign_key: true, null: false
      t.references :icon_image, foreign_key: true, null: false
      t.boolean :is_icon, null: false, default: true # true: アイコン画像, false: アイコンメーカー画像
      t.timestamps
    end
  end
end
