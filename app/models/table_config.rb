class TableConfig < ApplicationRecord
  validates :page_key, presence: true, uniqueness: true

  def self.for_page(key)
    find_or_initialize_by(page_key: key)
  end

  def visible_columns
    (columns || []).select { |c| c["default_visible"] }
  end

  def sortable_columns
    (columns || []).select { |c| c["sortable"] }
  end

  def enabled_filters
    (filters || []).select { |f| f["enabled"] }
  end

  def column_keys
    (columns || []).map { |c| c["key"] }
  end

  def visible_column_keys
    visible_columns.map { |c| c["key"] }
  end
end
