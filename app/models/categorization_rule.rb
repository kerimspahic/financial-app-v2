class CategorizationRule < ApplicationRecord
  belongs_to :user
  belongs_to :category

  enum :match_type, { contains: 0, starts_with: 1, exact: 2, regex: 3 }

  validates :pattern, presence: true
  validates :match_type, presence: true
  validates :priority, numericality: { only_integer: true }

  scope :ordered, -> { order(priority: :desc) }

  def matches?(description)
    case match_type
    when "contains"
      description.downcase.include?(pattern.downcase)
    when "starts_with"
      description.downcase.start_with?(pattern.downcase)
    when "exact"
      description.downcase == pattern.downcase
    when "regex"
      Regexp.new(pattern, Regexp::IGNORECASE).match?(description)
    end
  rescue RegexpError
    false
  end
end
