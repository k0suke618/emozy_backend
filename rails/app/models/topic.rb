class Topic < ApplicationRecord
  # アソシエーション
  has_many :posts, dependent: :destroy 
  has_many :post_reactions, through: :posts
  has_many :users, through: :posts

  # バリデーション
  validates :content, presence: true
end
