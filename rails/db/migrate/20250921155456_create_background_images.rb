class CreateBackgroundImages < ActiveRecord::Migration[7.2]
  def change
    create_table :background_images do |t|
      t.timestamps
    end
  end
end
