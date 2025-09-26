class PointType < ApplicationRecord
  # アソシエーション
  has_many :points, dependent: :destroy
  has_many :user_points, through: :points

  # バリデーション
  validates :content, presence: true, uniqueness: true
end
