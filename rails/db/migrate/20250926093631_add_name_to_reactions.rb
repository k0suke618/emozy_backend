class AddNameToReactions < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:reactions, :name)
      add_column :reactions, :name, :string, null: false
    end

    unless index_exists?(:reactions, :name, unique: true)
      add_index :reactions, :name, unique: true
    end
  end
end
