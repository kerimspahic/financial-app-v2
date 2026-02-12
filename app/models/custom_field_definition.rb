class CustomFieldDefinition < ApplicationRecord
  belongs_to :user

  enum :field_type, { text: 0, number: 1, date: 2, boolean: 3, select: 4 }, prefix: :field

  validates :name, presence: true, uniqueness: { scope: :user_id, message: "has already been used" }
  validates :field_type, presence: true

  scope :ordered, -> { order(:position, :name) }

  # Returns an array of select options from the options jsonb field
  # Expected format: { "choices" => ["Option A", "Option B"] }
  def select_choices
    options&.dig("choices") || []
  end
end
