class IconImage < ApplicationRecord
  # アソシエーション
  has_many :user_icons, dependent: :nullify
  has_many :icon_image_lists, foreign_key: 'image_id', dependent: :destroy
  has_many :users, through: :icon_image_lists, source: :user

  # バリデーション
  validates :image, presence: true
  validates :point, presence: true
end
