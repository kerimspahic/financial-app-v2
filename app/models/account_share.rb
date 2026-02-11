class AccountShare < ApplicationRecord
  belongs_to :account
  belongs_to :user

  enum :permission_level, { viewer: 0, editor: 1, admin: 2 }

  validates :user_id, uniqueness: { scope: :account_id, message: "already has access to this account" }

  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :pending, -> { where(accepted_at: nil) }

  before_create :generate_invitation_token

  def accepted?
    accepted_at.present?
  end

  def accept!
    update!(accepted_at: Time.current)
  end

  private

  def generate_invitation_token
    self.invitation_token ||= SecureRandom.urlsafe_base64(32)
  end
end
