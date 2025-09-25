class Point < ApplicationRecord
  # アソシエーション
  belongs_to :point_type
  belongs_to :user

  # バリデーション
  validates :point_type_id, presence: true
  validates :user_id, presence: true
  validates :value, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
