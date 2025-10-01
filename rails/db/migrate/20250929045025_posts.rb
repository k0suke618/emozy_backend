class Posts < ActiveRecord::Migration[7.2]
  def change
    # リアクションの種類を設定するカラムを追加
    add_column :posts, :is_set_reaction_1, :boolean, default: false, null: false
    add_column :posts, :is_set_reaction_2, :boolean, default: false, null: false
    add_column :posts, :is_set_reaction_3, :boolean, default: false, null: false
    add_column :posts, :is_set_reaction_4, :boolean, default: false, null: false
    add_column :posts, :is_set_reaction_5, :boolean, default: false, null: false
    add_column :posts, :is_set_reaction_6, :boolean, default: false, null: false
    add_column :posts, :is_set_reaction_7, :boolean, default: false, null: false
    add_column :posts, :is_set_reaction_8, :boolean, default: false, null: false
    add_column :posts, :is_set_reaction_9, :boolean, default: false, null: false
    add_column :posts, :is_set_reaction_10, :boolean, default: false, null: false
    add_column :posts, :is_set_reaction_11, :boolean, default: false, null: false
    add_column :posts, :is_set_reaction_12, :boolean, default: false, null: false
  end
end
