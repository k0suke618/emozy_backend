class Post < ApplicationRecord
  # アソシエーション
  belongs_to :user
  belongs_to :topic

  has_many :post_reactions, dependent: :destroy
  has_many :reactions, through: :post_reactions
  has_many :users_who_reacted, through: :post_reactions, source: :user

  has_many :favorites, dependent: :destroy
  has_many :users_who_favorited, through: :favorites, source: :user

  has_many :reports, dependent: :destroy

  # バリデーション
  validates :user_id, presence: true
  validates :topic_id, presence: true
  validates :content, presence: true, unless: -> { image.present? }
  validates :image, presence: true, unless: -> { content.present? }

  # is_set_reaction_n でtrueの数が1以上5以下であるようにする
  validate :reaction_count

  # nameカラムの追加
  validates :name, presence: true
  # nameはuser_idからuserDBのnameを参照して保存するようにする
  before_validation :set_name_from_user, if: -> { has_attribute?(:name) && (name.blank? || will_save_change_to_user_id?) }

  private

  def reaction_count
    count = 0
    (1..12).each do |i|
      count += 1 if send("is_set_reaction_#{i}")
    end
    errors.add(:base, "リアクションは1つ以上3つ以下にしてください") if count < 1 || count > 3
  end

  def set_name_from_user
    self.name = user&.name
  end
end
