require "nokogiri"

class OfxImportService
  include BalanceUpdatable

  attr_reader :headers, :rows

  def initialize(file_content, user, account: nil, mapping: {})
    @file_content = file_content
    @user = user
    @account = account
    @mapping = mapping
    @headers = [ "Date", "Description", "Amount", "Type", "Memo" ]
    parse_ofx
  end

  # Returns first N rows for preview display
  def preview_rows(limit: 10)
    @rows.first(limit)
  end

  # Returns auto-detected column mapping (fixed for OFX)
  def column_mapping
    { date: 0, description: 1, amount: 2, type: 3, notes: 4 }
  end

  # Performs the import, creating transactions with balance updates
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

  def parse_ofx
    @rows = []

    # OFX files can have SGML header before XML content
    # Strip the SGML header and find the XML portion
    content = clean_ofx_content(@file_content)

    begin
      doc = Nokogiri::XML(content) { |config| config.recover }

      # Find all STMTTRN elements (bank statement transactions)
      doc.xpath("//STMTTRN").each do |txn_node|
        date_raw = text_content(txn_node, "DTPOSTED")
        amount_raw = text_content(txn_node, "TRNAMT")
        name = text_content(txn_node, "NAME")
        memo = text_content(txn_node, "MEMO")
        txn_type = text_content(txn_node, "TRNTYPE")

        date = parse_ofx_date(date_raw)
        description = name.presence || memo.presence || "OFX Transaction"

        @rows << [ date&.strftime("%Y-%m-%d"), description, amount_raw, txn_type, memo ]
      end
    rescue Nokogiri::XML::SyntaxError => e
      Rails.logger.warn "[OfxImportService] XML parse error: #{e.message}"
      raise ArgumentError, "Invalid OFX file format: #{e.message}"
    end

    raise ArgumentError, "No transactions found in OFX file" if @rows.empty?
  end

  def clean_ofx_content(content)
    # OFX files often have an SGML-style header before the XML
    # Find the start of the XML/SGML document
    if content.include?("<OFX>")
      xml_start = content.index("<OFX>")
      sgml_content = content[xml_start..]

      # Convert SGML-style OFX to valid XML by closing unclosed tags
      # OFX 1.x uses SGML (no closing tags), OFX 2.x uses XML
      unless sgml_content.include?("</OFX>")
        sgml_content = convert_sgml_to_xml(sgml_content)
      end

      sgml_content
    else
      content
    end
  end

  def convert_sgml_to_xml(sgml)
    # Simple SGML-to-XML converter for OFX
    # Add closing tags where they are missing
    result = sgml.dup

    # Tags that contain data (not container tags) need closing
    data_tags = %w[DTPOSTED DTSTART DTEND TRNAMT TRNTYPE FITID NAME MEMO CHECKNUM REFNUM
                   ACCTID BANKID BRANCHID ACCTTYPE BALAMT DTASOF CURDEF]

    data_tags.each do |tag|
      result.gsub!(/<#{tag}>([^<\n]*)\n/) { "<#{tag}>#{$1}</#{tag}>\n" }
      result.gsub!(/<#{tag}>([^<\n]*)$/) { "<#{tag}>#{$1}</#{tag}>" }
    end

    result
  end

  def text_content(node, tag_name)
    el = node.at_xpath(tag_name) || node.at_xpath(tag_name.downcase)
    el&.text&.strip || ""
  end

  def parse_ofx_date(date_str)
    return nil if date_str.blank?

    # OFX dates: YYYYMMDD or YYYYMMDDHHMMSS or YYYYMMDDHHMMSS.XXX[TZ]
    clean = date_str.gsub(/\[.*\]/, "").strip
    if clean.length >= 8
      Date.new(clean[0..3].to_i, clean[4..5].to_i, clean[6..7].to_i)
    end
  rescue Date::Error
    nil
  end

  def build_transaction(row)
    date_str, description, amount_str, _txn_type, memo = row

    date = date_str.present? ? Date.parse(date_str) : nil
    return nil if date.nil?
    return nil if description.blank?

    amount = BigDecimal(amount_str.to_s.gsub(/[^0-9.\-]/, ""))
    return nil if amount.zero?

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
      notes: memo.presence,
      needs_review: true
    )
  rescue ArgumentError, TypeError
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
