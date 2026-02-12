class Webhook < ApplicationRecord
  belongs_to :user

  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }
  validates :secret, presence: true

  scope :active, -> { where(active: true) }

  AVAILABLE_EVENTS = %w[
    transaction.created
    transaction.updated
    transaction.deleted
  ].freeze

  def subscribes_to?(event_name)
    events.blank? || events.empty? || events.include?(event_name)
  end
end
