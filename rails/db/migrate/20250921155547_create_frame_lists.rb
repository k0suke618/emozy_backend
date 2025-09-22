class CreateFrameLists < ActiveRecord::Migration[7.2]
  def change
    create_table :frame_lists do |t|
      t.timestamps
    end
  end
end
