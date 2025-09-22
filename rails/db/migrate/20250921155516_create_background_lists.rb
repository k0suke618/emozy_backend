class CreateBackgroundLists < ActiveRecord::Migration[7.2]
  def change
    create_table :background_lists do |t|
      t.timestamps
    end
  end
end
