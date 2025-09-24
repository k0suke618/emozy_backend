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

  has_one :user_icon, dependent: :destroy
  has_many :icon_images, through: :icon_image_lists, source: :image

  has_many :favorites, dependent: :destroy
  has_many :favorite_posts, through: :favorites, source: :post
  has_many :favorite_topics, through: :favorites, source: :topic

  # 自分がフォローしているユーザーを取得するための関連
  has_many :active_follows, class_name: 'Follow', foreign_key: 'follower_id', dependent: :destroy
  has_many :followings, through: :active_follows, source: :followed
  # 自分をフォローしているユーザーを取得するための関連
  has_many :passive_follows, class_name: 'Follow', foreign_key: 'followed_id', dependent: :destroy
  has_many :followers, through: :passive_follows, source: :follower

  # バリデーション
  validates :name, presence: true
  validates :point, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # パスワードのハッシュ化と認証
  has_secure_password
end
