class UserIcon < ApplicationRecord
  # アソシエーション
  belongs_to :user
  belongs_to :icon_image

  # バリデーション
  validates :user_id, presence: true, uniqueness: true
  validates :icon_image_id, presence: true
end
