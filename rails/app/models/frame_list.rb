class FrameList < ApplicationRecord
  # アソシエーション
  belongs_to :user
  belongs_to :image, class_name: 'FrameImage'

  # バリデーション
  validates :user_id, presence: true, uniqueness: { scope: :image_id }
  validates :image_id, presence: true
end
