class CreateBackgroundImages < ActiveRecord::Migration[7.2]
  def change
    create_table :background_images do |t|
      t.string :image, null: false
      t.bigint :point, null: false, default: 0
      t.timestamps
    end
  end
end
