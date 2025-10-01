class Users < ActiveRecord::Migration[7.2]
  def change
    # nameをnull trueに変更
    change_column_null :users, :name, true
  end
end
