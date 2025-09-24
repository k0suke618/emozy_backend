class ReportType < ApplicationRecord
  # アソシエーション
  has_many :reports, dependent: :destroy

  # バリデーション
  validates :content, presence: true, uniqueness: true
end
