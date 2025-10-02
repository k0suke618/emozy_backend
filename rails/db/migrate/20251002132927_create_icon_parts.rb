class CreateIconParts < ActiveRecord::Migration[7.2]
  def change
    create_table :icon_parts do |t|
      # icon_part_type_idの外部キー制約を追加
      t.references :icon_parts_type, null: false, foreign_key: true
      # 画像のパスを保存するカラム
      t.string :image, null: false
      t.timestamps
    end
  end
end
