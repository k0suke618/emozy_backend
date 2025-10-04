class AddIconImageUrlToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :icon_image_url, :string, null: false, default: ""
  end
end
