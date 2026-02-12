class PdfImportService
  include BalanceUpdatable

  PDF_READER_AVAILABLE = begin
    require "pdf-reader"
    true
  rescue LoadError
    false
  end

  attr_reader :headers, :rows

  # Common date patterns found in bank statements
  DATE_PATTERNS = [
    /(\d{1,2}\/\d{1,2}\/\d{2,4})/,    # MM/DD/YYYY or DD/MM/YYYY
    /(\d{4}-\d{2}-\d{2})/,              # YYYY-MM-DD
    /(\d{1,2}-\d{1,2}-\d{2,4})/,        # MM-DD-YYYY or DD-MM-YYYY
    /(\w{3}\s+\d{1,2},?\s+\d{4})/       # Jan 15, 2024
  ].freeze

  DATE_FORMATS = [
    "%m/%d/%Y", "%m/%d/%y", "%d/%m/%Y", "%d/%m/%y",
    "%Y-%m-%d", "%m-%d-%Y", "%m-%d-%y",
    "%b %d, %Y", "%b %d %Y", "%B %d, %Y", "%B %d %Y"
  ].freeze

  # Amount patterns: currency symbols, negative numbers, parenthesized negatives
  AMOUNT_PATTERN = /[-]?\$?\s*[\d,]+\.\d{2}|\([\$\d,]+\.\d{2}\)/

  def initialize(file_content, user, account: nil, mapping: {})
    @file_content = file_content
    @user = user
    @account = account
    @mapping = mapping
    @headers = [ "Date", "Description", "Amount" ]
    parse_pdf
  end

  def preview_rows(limit: 10)
    @rows.first(limit)
  end

  def column_mapping
    { date: 0, description: 1, amount: 2 }
  end

  def import!
    result = { imported: 0, skipped: 0, duplicates: 0, errors: [] }

    if @rows.empty?
      result[:errors] << "No transactions could be extracted from the PDF"
      return result
    end

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

  def parse_pdf
    @rows = []

    unless PDF_READER_AVAILABLE
      raise ArgumentError, "PDF import requires the 'pdf-reader' gem. Please run: bundle install"
    end

    begin
      # pdf-reader requires IO or a file path; for string content we use StringIO
      reader = PDF::Reader.new(StringIO.new(@file_content))

      all_text = reader.pages.map(&:text).join("\n")
      extract_transactions_from_text(all_text)
    rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError => e
      Rails.logger.warn "[PdfImportService] PDF parse error: #{e.message}"
      raise ArgumentError, "Unable to read PDF file: #{e.message}"
    rescue => e
      Rails.logger.warn "[PdfImportService] Unexpected error: #{e.message}"
      raise ArgumentError, "Failed to process PDF: #{e.message}"
    end

    if @rows.empty?
      raise ArgumentError, "No transactions could be extracted from this PDF. The format may not be supported. Try exporting as CSV from your bank instead."
    end
  end

  def extract_transactions_from_text(text)
    lines = text.split("\n").map(&:strip).reject(&:empty?)

    lines.each do |line|
      # Try to find a date in the line
      date = extract_date(line)
      next unless date

      # Try to find an amount in the line
      amounts = line.scan(AMOUNT_PATTERN)
      next if amounts.empty?

      # Use the last amount found (typically the actual transaction amount)
      amount_str = amounts.last.to_s

      # Extract description: text between the date and the amount
      description = extract_description(line, date, amount_str)
      next if description.blank?

      @rows << [ date.strftime("%Y-%m-%d"), description.strip, amount_str ]
    end
  end

  def extract_date(line)
    DATE_PATTERNS.each do |pattern|
      match = line.match(pattern)
      next unless match

      date_str = match[1]
      DATE_FORMATS.each do |fmt|
        begin
          return Date.strptime(date_str, fmt)
        rescue Date::Error
          next
        end
      end

      # Fallback
      begin
        return Date.parse(date_str)
      rescue Date::Error
        next
      end
    end

    nil
  end

  def extract_description(line, date, amount_str)
    # Remove the date portion
    desc = line.dup
    DATE_PATTERNS.each do |pattern|
      desc = desc.sub(pattern, "")
    end

    # Remove the amount portion
    escaped_amount = Regexp.escape(amount_str)
    desc = desc.sub(/#{escaped_amount}/, "")

    # Clean up whitespace and common delimiters
    desc = desc.gsub(/\s{2,}/, " ").strip
    desc = desc.sub(/^[\s\-\*]+/, "").sub(/[\s\-\*]+$/, "").strip

    desc.presence
  end

  def build_transaction(row)
    date_str, description, amount_str = row

    date = Date.parse(date_str) rescue nil
    return nil if date.nil?
    return nil if description.blank?

    amount = clean_amount(amount_str)
    return nil if amount.nil? || amount.zero?

    transaction_type = amount >= 0 ? :income : :expense
    category = find_category(description, transaction_type)

    @user.transactions.build(
      account: @account,
      date: date,
      description: description,
      payee: description,
      amount: amount.abs,
      transaction_type: transaction_type,
      category: category,
      notes: "Imported from PDF statement",
      needs_review: true
    )
  end

  def clean_amount(value)
    return nil if value.blank?

    cleaned = value.to_s.gsub(/[$\s,]/, "")

    # Handle parenthesized negatives: (100.00) -> -100.00
    if cleaned.match?(/\A\([\d.]+\)\z/)
      cleaned = "-" + cleaned.tr("()", "")
    end

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

  def find_category(description, transaction_type)
    if description.present?
      @user.categorization_rules.ordered.each do |rule|
        return rule.category if rule.matches?(description)
      end
    end

    @user.categories.find_by(category_type: transaction_type) ||
      @user.categories.first
  end
end
