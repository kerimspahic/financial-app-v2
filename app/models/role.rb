class Role < ApplicationRecord
  belongs_to :user
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions
  has_many :user_roles, dependent: :destroy

  validates :name, presence: true
end
