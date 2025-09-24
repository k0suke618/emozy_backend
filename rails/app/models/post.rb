class Post < ApplicationRecord
  # アソシエーション
  belongs_to :user
  belongs_to :topic

  has_many :post_reactions, dependent: :destroy
  has_many :reactions, through: :post_reactions
  has_many :users_who_reacted, through: :post_reactions, source: :user

  has_many :favorites, dependent: :destroy
  has_many :users_who_favorited, through: :favorites, source: :user

  # バリデーション
  validates :user_id, presence: true
  validates :topic_id, presence: true
  validates :content, presence: true, unless: -> { image.present? }
  validates :image, presence: true, unless: -> { content.present? }
end
