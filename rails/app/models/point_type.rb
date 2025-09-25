class PointType < ApplicationRecord
  # アソシエーション
  has_many :points, dependent: :destroy

  # バリデーション
  validates :content, presence: true, uniqueness: true
end
