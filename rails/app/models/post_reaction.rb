class PostReaction < ApplicationRecord
  # アソシエーション
  belongs_to :user
  belongs_to :post
  belongs_to :reaction
  has_one :topic, through: :post

  # バリデーション
  validates :user_id, presence: true, uniqueness: { scope: [:post_id, :reaction_id] }
  validates :post_id, presence: true
  validates :reaction_id, presence: true

  # postsテーブルのis_set_reaction_nがtrueのものに対応するリアクションのみ許可
  validate :reaction_must_be_set_in_post
  def reaction_must_be_set_in_post
    return if post.nil? || reaction.nil?

    reaction_index = reaction.id
    unless post.send("is_set_reaction_#{reaction_index}")
      errors.add(:reaction_id, "この投稿ではこのリアクションは許可されていません")
    end
  end
end
