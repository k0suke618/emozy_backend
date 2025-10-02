class AddNameInPosts < ActiveRecord::Migration[7.2]
  def change
    # user_idからユーザー名を取得して保存するためのnameカラムを追加
    add_column :posts, :name, :string
  end
end
