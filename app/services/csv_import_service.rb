require "csv"

class CsvImportService
  include BalanceUpdatable

  FIELD_MAPPINGS = {
    date: %w[date transaction_date trans_date posting_date post_date],
    description: %w[description desc memo narrative payee details transaction_description],
    amount: %w[amount total sum value net_amount],
    credit: %w[credit credit_amount deposit deposits money_in],
    debit: %w[debit debit_amount withdrawal withdrawals money_out charge],
    category: %w[category type category_name],
    notes: %w[notes note memo reference ref]
  }.freeze

  DATE_FORMATS = [
    "%m/%d/%Y",    # 01/31/2024
    "%Y-%m-%d",    # 2024-01-31
    "%d/%m/%Y",    # 31/01/2024
    "%m-%d-%Y",    # 01-31-2024
    "%d-%m-%Y",    # 31-01-2024
    "%m/%d/%y",    # 01/31/24
    "%d/%m/%y",    # 31/01/24
    "%Y/%m/%d",    # 2024/01/31
    "%b %d, %Y",   # Jan 31, 2024
    "%B %d, %Y",   # January 31, 2024
    "%d %b %Y",    # 31 Jan 2024
    "%d %B %Y"     # 31 January 2024
  ].freeze

  attr_reader :headers, :rows

  def initialize(csv_content, user, account: nil, mapping: {})
    @csv_content = csv_content
    @user = user
    @account = account
    @mapping = normalize_mapping(mapping)
    parse_csv
  end

  # Returns auto-detected column mapping: { field_name => column_index }
  def column_mapping
    @column_mapping ||= detect_columns
  end

  # Returns the effective mapping (user-provided overrides auto-detected)
  def effective_mapping
    if @mapping.any?
      @mapping
    else
      column_mapping
    end
  end

  # Returns first N rows for preview display
  def preview_rows(limit: 10)
    @rows.first(limit)
  end

  # Performs the import, creating transactions with balance updates
  def import!
    result = { imported: 0, skipped: 0, errors: [] }
    mapping = effective_mapping

    unless mapping[:date]
      result[:errors] << "No date column mapped. Cannot import."
      return result
    end

    unless mapping[:description]
      result[:errors] << "No description column mapped. Cannot import."
      return result
    end

    unless mapping[:amount] || (mapping[:credit] || mapping[:debit])
      result[:errors] << "No amount, credit, or debit column mapped. Cannot import."
      return result
    end

    ActiveRecord::Base.transaction do
      @rows.each_with_index do |row, index|
        row_num = index + 2 # +2 for header row and 1-based indexing

        begin
          transaction = build_transaction(row, mapping)

          if transaction.nil?
            result[:skipped] += 1
            next
          end

          if transaction.save
            update_account_balance(transaction)
            result[:imported] += 1
          else
            result[:errors] << "Row #{row_num}: #{transaction.errors.full_messages.join(', ')}"
            result[:skipped] += 1
          end
        rescue => e
          result[:errors] << "Row #{row_num}: #{e.message}"
          result[:skipped] += 1
        end
      end
    end

    result
  end

  private

  def parse_csv
    parsed = CSV.parse(@csv_content, headers: true, liberal_parsing: true, skip_blanks: true)
    @headers = parsed.headers.map { |h| h&.strip }
    @rows = parsed.map { |row| row.fields.map { |f| f&.strip } }
  rescue CSV::MalformedCSVError => e
    @headers = []
    @rows = []
    raise ArgumentError, "Invalid CSV file: #{e.message}"
  end

  def normalize_mapping(mapping)
    return {} if mapping.blank?

    normalized = {}
    mapping.each do |field, col_index|
      next if col_index.blank? || col_index.to_s == ""

      normalized[field.to_sym] = col_index.to_i
    end
    normalized
  end

  def detect_columns
    mapping = {}

    @headers.each_with_index do |header, index|
      next if header.nil?

      normalized = header.downcase.gsub(/[^a-z0-9]/, "_").gsub(/_+/, "_").gsub(/\A_|_\z/, "")

      FIELD_MAPPINGS.each do |field, patterns|
        next if mapping[field] # Don't overwrite if already matched

        if patterns.any? { |pattern| normalized == pattern || normalized.include?(pattern) }
          mapping[field] = index
        end
      end
    end

    # If we have both credit and debit but no amount, that's fine (separate columns)
    # If we have amount but also credit/debit, prefer amount
    if mapping[:amount] && (mapping[:credit] || mapping[:debit])
      mapping.delete(:credit)
      mapping.delete(:debit)
    end

    mapping
  end

  def build_transaction(row, mapping)
    date = parse_date(row[mapping[:date]])
    return nil if date.nil?

    description = row[mapping[:description]]
    return nil if description.blank?

    amount, transaction_type = determine_amount_and_type(row, mapping)
    return nil if amount.nil? || amount.zero?

    category = find_category(row, mapping, transaction_type)

    @user.transactions.build(
      account: @account,
      date: date,
      description: description,
      amount: amount.abs,
      transaction_type: transaction_type,
      category: category,
      notes: mapping[:notes] ? row[mapping[:notes]] : nil
    )
  end

  def parse_date(value)
    return nil if value.blank?

    # Try each format
    DATE_FORMATS.each do |fmt|
      begin
        return Date.strptime(value.strip, fmt)
      rescue Date::Error
        next
      end
    end

    # Fallback: let Ruby try to parse it
    begin
      Date.parse(value.strip)
    rescue Date::Error
      nil
    end
  end

  def determine_amount_and_type(row, mapping)
    if mapping[:amount]
      raw = clean_amount(row[mapping[:amount]])
      return [ nil, nil ] if raw.nil?

      if raw >= 0
        [ raw, :income ]
      else
        [ raw.abs, :expense ]
      end
    elsif mapping[:credit] || mapping[:debit]
      credit = clean_amount(row[mapping[:credit]]) if mapping[:credit]
      debit = clean_amount(row[mapping[:debit]]) if mapping[:debit]

      if credit && credit > 0
        [ credit, :income ]
      elsif debit && debit > 0
        [ debit, :expense ]
      elsif credit && credit < 0
        # Some banks put negative credits as debits
        [ credit.abs, :expense ]
      elsif debit && debit < 0
        [ debit.abs, :income ]
      else
        [ nil, nil ]
      end
    else
      [ nil, nil ]
    end
  end

  def clean_amount(value)
    return nil if value.blank?

    # Remove currency symbols, spaces, and common separators (keep minus sign and decimal point)
    cleaned = value.to_s.gsub(/[$\u20AC\u00A3\u00A5,\s]/, "")
    # Handle parentheses as negative: (100.00) -> -100.00
    if cleaned.match?(/\A\([\d.]+\)\z/)
      cleaned = "-" + cleaned.tr("()", "")
    end

    BigDecimal(cleaned)
  rescue ArgumentError
    nil
  end

  def find_category(row, mapping, transaction_type)
    # First, try to use category from CSV
    if mapping[:category]
      csv_category_name = row[mapping[:category]]
      if csv_category_name.present?
        category = @user.categories.find_by("LOWER(name) = ?", csv_category_name.downcase.strip)
        return category if category
      end
    end

    # Second, try categorization rules
    description = row[mapping[:description]]
    if description.present?
      @user.categorization_rules.ordered.each do |rule|
        if rule.matches?(description)
          return rule.category
        end
      end
    end

    # Fallback: use first category matching the transaction type
    @user.categories.find_by(category_type: transaction_type) ||
      @user.categories.first
  end
end
