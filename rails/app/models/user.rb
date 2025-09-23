class User < ApplicationRecord
  # アソシエーション
  belongs_to :background, class_name: 'BackgroundImage', optional: true
  belongs_to :frame, class_name: 'FrameImage', optional: true
  has_many :background_lists, dependent: :destroy
  has_many :background_images, through: :background_lists, source: :image
  has_many :frame_lists, dependent: :destroy
  has_many :frame_images, through: :frame_lists, source: :image

  has_many :posts, dependent: :destroy
  has_many :post_reactions, dependent: :destroy
  has_many :reactions, through: :post_reactions
  has_many :topics, through: :posts

  # バリデーション
  validates :name, presence: true
  validates :point, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # パスワードのハッシュ化と認証
  has_secure_password
end
