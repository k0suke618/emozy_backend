class UserPoint < ApplicationRecord
  belongs_to :user
  belongs_to :point

  validates :user_id, presence: true
  validates :point_id, presence: true
  validates :value, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :point_id, uniqueness: { scope: :user_id }
end
