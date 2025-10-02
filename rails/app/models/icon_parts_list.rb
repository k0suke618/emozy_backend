class IconPartsList < ApplicationRecord
  # アソシエーション
  belongs_to :user
  # ユーザーが所有しているアイコンパーツリスト
  has_many :users_owning_this, through: :user, source: :icon_parts_lists

  # バリデーション
  validates :user_id, presence: true
  validates :eyes_image, presence: true
  validates :mouth_image, presence: true
  validates :skin_image, presence: true
  validates :front_hair_image, presence: true
  validates :back_hair_image, presence: true
  validates :eyebrows_image, presence: true
  validates :high_light_image, presence: true
  validates :clothing_image, presence: true
  validates :accessory_image, presence: true
end