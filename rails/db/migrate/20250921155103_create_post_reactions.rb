class CreatePostReactions < ActiveRecord::Migration[7.2]
  def change
    create_table :post_reactions do |t|
      t.timestamps
    end
  end
end
