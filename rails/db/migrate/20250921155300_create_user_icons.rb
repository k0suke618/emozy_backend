class CreateUserIcons < ActiveRecord::Migration[7.2]
  def change
    create_table :user_icons do |t|
      t.timestamps
    end
  end
end
