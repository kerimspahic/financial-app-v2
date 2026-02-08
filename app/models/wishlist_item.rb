class WishlistItem < ApplicationRecord
  belongs_to :user

  validates :name, presence: true

  scope :unpurchased, -> { where(purchased: false) }
end
