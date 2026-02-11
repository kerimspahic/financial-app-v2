class SavedFilter < ApplicationRecord
  belongs_to :user

  validates :name, presence: true, uniqueness: { scope: [ :user_id, :page_key ] }
  validates :page_key, presence: true

  scope :for_page, ->(key) { where(page_key: key) }
  scope :defaults, -> { where(is_default: true) }
end
