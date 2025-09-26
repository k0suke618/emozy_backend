class Point < ApplicationRecord
  # アソシエーション
  belongs_to :point_type
  has_many :user_points, dependent: :destroy

  # バリデーション
  validates :point_type_id, presence: true
  validates :value, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :value, uniqueness: { scope: :point_type_id }
end
