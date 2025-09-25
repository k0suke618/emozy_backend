class Reaction < ApplicationRecord
  # アソシエーション
  has_many :post_reactions, dependent: :destroy
  has_many :users, through: :post_reactions
  has_many :posts, through: :post_reactions

  # バリデーション
  validates :name, presence: true, uniqueness: true
  validates :image, presence: true
end
