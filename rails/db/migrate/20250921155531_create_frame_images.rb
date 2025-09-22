class CreateFrameImages < ActiveRecord::Migration[7.2]
  def change
    create_table :frame_images do |t|
      t.timestamps
    end
  end
end
