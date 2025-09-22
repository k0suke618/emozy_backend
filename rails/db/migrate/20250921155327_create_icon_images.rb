class CreateIconImages < ActiveRecord::Migration[7.2]
  def change
    create_table :icon_images do |t|
      t.timestamps
    end
  end
end
