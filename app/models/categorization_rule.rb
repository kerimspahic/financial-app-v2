class CategorizationRule < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true

  enum :match_type, { contains: 0, starts_with: 1, exact: 2, regex: 3 }
  enum :match_field, { description: 0, payee: 1, amount: 2, notes: 3 }, prefix: :field

  validates :pattern, presence: true
  validates :match_type, presence: true
  validates :priority, numericality: { only_integer: true }
  validate :has_category_or_actions

  scope :ordered, -> { order(priority: :desc) }
  scope :active, -> { where(active: true) }

  # Apply all configured actions to a transaction
  def apply_actions!(transaction)
    # Legacy support: if category_id is set directly and no actions, apply it
    if actions.blank? && category_id.present?
      transaction.category_id = category_id
      return
    end

    Array(actions).each do |action|
      apply_single_action!(transaction, action)
    end
  end

  def matches?(text_or_transaction)
    field_value = extract_field_value(text_or_transaction)
    return false if field_value.blank?

    case match_type
    when "contains"
      field_value.downcase.include?(pattern.downcase)
    when "starts_with"
      field_value.downcase.start_with?(pattern.downcase)
    when "exact"
      field_value.downcase == pattern.downcase
    when "regex"
      Regexp.new(pattern, Regexp::IGNORECASE).match?(field_value)
    end
  rescue RegexpError
    false
  end

  # Human-readable summary of the actions
  def actions_summary
    return category&.name || "No action" if actions.blank? && category_id.present?
    return "No actions" if actions.blank?

    Array(actions).map do |action|
      case action["type"]
      when "set_category"
        cat = Category.find_by(id: action["value"])
        "Set category: #{cat&.name || 'Unknown'}"
      when "add_tag"
        tag = Tag.find_by(id: action["value"])
        "Add tag: #{tag&.name || 'Unknown'}"
      when "set_payee"
        "Set payee: #{action['value']}"
      when "set_notes"
        "Set notes: #{action['value']}"
      when "set_flag"
        "Set flag: #{action['value']&.humanize}"
      when "mark_reviewed"
        "Mark as reviewed"
      when "exclude_from_reports"
        "Exclude from reports"
      else
        action["type"]&.humanize || "Unknown"
      end
    end.join(", ")
  end

  private

  def extract_field_value(text_or_transaction)
    if text_or_transaction.is_a?(String)
      # Legacy: plain string always matches against description
      return text_or_transaction
    end

    case match_field
    when "description"
      text_or_transaction.description
    when "payee"
      text_or_transaction.payee
    when "amount"
      text_or_transaction.amount.to_s
    when "notes"
      text_or_transaction.notes
    end
  end

  def apply_single_action!(transaction, action)
    case action["type"]
    when "set_category"
      transaction.category_id = action["value"] if action["value"].present?
    when "add_tag"
      tag = transaction.user.tags.find_by(id: action["value"])
      transaction.tags << tag if tag && !transaction.tags.include?(tag)
    when "set_payee"
      transaction.payee = action["value"]
    when "set_notes"
      transaction.notes = action["value"]
    when "set_flag"
      transaction.flag = action["value"]
    when "mark_reviewed"
      transaction.needs_review = false
    when "exclude_from_reports"
      transaction.exclude_from_reports = true
    end
  end

  def has_category_or_actions
    if category_id.blank? && actions.blank?
      errors.add(:base, "Rule must have a category or at least one action")
    end
  end
end
