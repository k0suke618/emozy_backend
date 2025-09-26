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
end
