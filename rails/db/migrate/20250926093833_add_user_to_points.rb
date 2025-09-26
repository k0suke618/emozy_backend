class AddUserToPoints < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:points, :user_id)
      add_reference :points, :user, null: false, foreign_key: true
    end
  end
end
