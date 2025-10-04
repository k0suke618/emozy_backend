class IconPartsType < ApplicationRecord
  # contentカラムにユニーク制約を追加
  validates :content, presence: true, uniqueness: true
end