class Reaction < ApplicationRecord
  # アソシエーション
  has_many :post_reactions, dependent: :destroy
  has_many :users, through: :post_reactions
  has_many :posts, through: :post_reactions

  # バリデーション
  validates :name, presence: true, uniqueness: true

  DEFAULT_REACTIONS = {
    1 => { name: 'Reaction 1', image: '' },
    2 => { name: 'Reaction 2', image: '' },
    3 => { name: 'Reaction 3', image: '' },
    4 => { name: 'Reaction 4', image: '' },
    5 => { name: 'Reaction 5', image: '' },
    6 => { name: 'Reaction 6', image: '' },
    7 => { name: 'Reaction 7', image: '' },
    8 => { name: 'Reaction 8', image: '' },
    9 => { name: 'Reaction 9', image: '' },
    10 => { name: 'Reaction 10', image: '' },
    11 => { name: 'Reaction 11', image: '' },
    12 => { name: 'Reaction 12', image: '' }
  }.freeze

  class << self
    # 指定されたリアクション番号のデフォルトリアクションを作成
    # reaction_numbersは配列または単一の番号
    def ensure_defaults!(reaction_numbers)
      Array(reaction_numbers).each do |reaction_number|
        ensure_default!(reaction_number)
      end
    end

    # 指定されたリアクション番号のデフォルトリアクションを作成
    def ensure_default!(reaction_number)
      number = Integer(reaction_number, exception: false)
      return unless number&.between?(1, 12)

      attributes = DEFAULT_REACTIONS[number]
      return unless attributes

      # idを指定して作成（既に存在する場合は無視）
      find_or_create_by!(id: number) do |reaction|
        reaction.name = attributes.fetch(:name)
        reaction.image = attributes.fetch(:image)
      end
    end
  end
end
