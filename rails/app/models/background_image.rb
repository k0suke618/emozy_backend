class BackgroundImage < ApplicationRecord
  # アソシエーション
  has_many :users, foreign_key: 'background_id'
  has_many :background_lists, foreign_key: :image_id, dependent: :destroy
  has_many :users_owning_this, through: :background_lists, source: :user

  # バリデーション
  validates :image, presence: true
  validates :point, presence: true
end
