class Report < ApplicationRecord
  # アソシエーション
  belongs_to :report_type
  belongs_to :post
  belongs_to :user

  # バリデーション
  validates :report_type_id, presence: true
  validates :post_id, presence: true
  validates :user_id, presence: true, uniqueness: { scope: :post_id, message: "この投稿はすでに報告済みです。" }
  validates :content, presence: true
end
