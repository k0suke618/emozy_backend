class FrameImage < ApplicationRecord
  # アソシエーション
  has_many :users, foreign_key: 'frame_id'
  has_many :frame_lists, foreign_key: :image_id, dependent: :destroy
  has_many :users_owning_this, through: :frame_lists, source: :user

  # バリデーション
  validates :image, presence: true
  validates :point, presence: true
end
