class QifImportService
  include BalanceUpdatable

  attr_reader :headers, :rows

  DATE_FORMATS = [
    "%m/%d/%Y",    # 01/31/2024
    "%m/%d/%y",    # 01/31/24
    "%d/%m/%Y",    # 31/01/2024
    "%d/%m/%y",    # 31/01/24
    "%Y-%m-%d",    # 2024-01-31
    "%m-%d-%Y",    # 01-31-2024
    "%m-%d-%y"     # 01-31-24
  ].freeze

  def initialize(file_content, user, account: nil, mapping: {})
    @file_content = file_content
    @user = user
    @account = account
    @mapping = mapping
    @headers = [ "Date", "Amount", "Payee", "Memo", "Category" ]
    parse_qif
  end

  # Returns first N rows for preview display
  def preview_rows(limit: 10)
    @rows.first(limit)
  end

  # Returns auto-detected column mapping (fixed for QIF)
  def column_mapping
    { date: 0, amount: 1, payee: 2, notes: 3, category: 4 }
  end

  # Performs the import
  def import!
    result = { imported: 0, skipped: 0, duplicates: 0, errors: [] }

    ActiveRecord::Base.transaction do
      @rows.each_with_index do |row, index|
        row_num = index + 1

        begin
          transaction = build_transaction(row)

          if transaction.nil?
            result[:skipped] += 1
            next
          end

          if duplicate_exists?(transaction)
            result[:duplicates] += 1
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

  def parse_qif
    @rows = []
    current_record = {}

    @file_content.each_line do |line|
      line = line.strip
      next if line.empty?

      # Skip QIF type header (e.g., !Type:Bank)
      next if line.start_with?("!")

      case line[0]
      when "D"
        current_record[:date] = line[1..].strip
      when "T", "U"
        # T = amount, U = amount (alternate)
        current_record[:amount] ||= line[1..].strip
      when "P"
        current_record[:payee] = line[1..].strip
      when "M"
        current_record[:memo] = line[1..].strip
      when "L"
        current_record[:category] = line[1..].strip
      when "N"
        current_record[:number] = line[1..].strip
      when "^"
        # End of record separator
        if current_record[:date].present? || current_record[:amount].present?
          @rows << [
            current_record[:date],
            current_record[:amount],
            current_record[:payee],
            current_record[:memo],
            current_record[:category]
          ]
        end
        current_record = {}
      end
    end

    # Handle last record if no trailing ^
    if current_record[:date].present? || current_record[:amount].present?
      @rows << [
        current_record[:date],
        current_record[:amount],
        current_record[:payee],
        current_record[:memo],
        current_record[:category]
      ]
    end

    raise ArgumentError, "No transactions found in QIF file" if @rows.empty?
  end

  def build_transaction(row)
    date_str, amount_str, payee, memo, category_name = row

    date = parse_qif_date(date_str)
    return nil if date.nil?

    amount = clean_amount(amount_str)
    return nil if amount.nil? || amount.zero?

    transaction_type = amount >= 0 ? :income : :expense
    description = payee.presence || memo.presence || "QIF Transaction"
    category = find_category(category_name, description, transaction_type)

    @user.transactions.build(
      account: @account,
      date: date,
      description: description,
      payee: payee,
      amount: amount.abs,
      transaction_type: transaction_type,
      category: category,
      notes: memo.presence,
      needs_review: true
    )
  end

  def parse_qif_date(date_str)
    return nil if date_str.blank?

    # QIF dates can use various formats, including ' instead of / for year 2000+
    cleaned = date_str.gsub("'", "/").gsub("-", "/")

    DATE_FORMATS.each do |fmt|
      begin
        return Date.strptime(cleaned, fmt)
      rescue Date::Error
        next
      end
    end

    # Fallback
    begin
      Date.parse(cleaned)
    rescue Date::Error
      nil
    end
  end

  def clean_amount(value)
    return nil if value.blank?
    cleaned = value.to_s.gsub(/[$,\s]/, "")
    BigDecimal(cleaned)
  rescue ArgumentError
    nil
  end

  def duplicate_exists?(transaction)
    scope = @user.transactions.where(
      account_id: transaction.account_id,
      amount: transaction.amount,
      description: transaction.description
    )
    scope.where(date: (transaction.date - 1.day)..(transaction.date + 1.day)).exists?
  end

  def find_category(category_name, description, transaction_type)
    # Try QIF category name first
    if category_name.present?
      # QIF categories can have subcategories like "Food:Groceries" -- use the first part
      primary_name = category_name.split(":").first.strip
      category = @user.categories.find_by("LOWER(name) = ?", primary_name.downcase)
      return category if category
    end

    # Try categorization rules
    if description.present?
      @user.categorization_rules.ordered.each do |rule|
        return rule.category if rule.matches?(description)
      end
    end

    # Fallback
    @user.categories.find_by(category_type: transaction_type) ||
      @user.categories.first
  end
end
