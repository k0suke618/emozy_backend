class Favorite < ApplicationRecord
  # アソシエーション
  belongs_to :user
  belongs_to :post
  belongs_to :topic

  # バリデーション
  validates :user_id, presence: true, uniqueness: { scope: :post_id, message: "すでにお気に入りに登録されています" }
  validates :post_id, presence: true
  validates :topic_id, presence: true
end
