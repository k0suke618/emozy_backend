class IconPart < ApplicationRecord
  # アソシエーション
  belongs_to :icon_parts_type

  # バリデーション
  validates :icon_parts_type_id, presence: true
  validates :image, presence: true

  # icon_parts_typeが一致しているものを取得するスコープ
  scope :by_type, ->(type_id) { where(icon_parts_type_id: type_id) }
end