class ImportsController < ApplicationController
  require_permission "manage_imports"

  ACCEPTED_EXTENSIONS = %w[.csv .ofx .qfx .qif .pdf].freeze
  ACCEPTED_CONTENT_TYPES = %w[
    text/csv application/csv text/plain application/vnd.ms-excel
    application/x-ofx application/ofx
    application/x-qfx
    application/qif application/x-qif
    application/pdf
    application/octet-stream
  ].freeze

  def new
    @accounts = current_user.accounts.active.order(:name)
  end

  def preview
    file = params[:file]

    if file.blank?
      redirect_to new_import_path, alert: "Please select a file to import."
      return
    end

    ext = detect_file_extension(file)
    unless ACCEPTED_EXTENSIONS.include?(ext)
      redirect_to new_import_path, alert: "Invalid file type. Supported formats: CSV, OFX, QFX, QIF, PDF."
      return
    end

    file_content = file.read.force_encoding("UTF-8")
    file_content = file_content.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

    session[:import_content] = file_content
    session[:import_filename] = file.original_filename
    session[:import_type] = ext

    begin
      @service = build_service(ext, file_content, current_user)
      @headers = @service.headers
      @column_mapping = @service.column_mapping
      @preview_rows = @service.preview_rows
      @accounts = current_user.accounts.active.order(:name)
      @categories = current_user.categories.order(:name)
      @filename = file.original_filename
      @total_rows = @service.rows.size
      @file_type = ext
    rescue ArgumentError => e
      redirect_to new_import_path, alert: e.message
    end
  end

  def create
    file_content = session.delete(:import_content)
    filename = session.delete(:import_filename)
    file_type = session.delete(:import_type)

    # Fallback to legacy session keys for CSV
    if file_content.blank?
      file_content = session.delete(:csv_import_content)
      filename = session.delete(:csv_import_filename)
      file_type = ".csv"
    end

    if file_content.blank?
      redirect_to new_import_path, alert: "Import session expired. Please upload again."
      return
    end

    account = current_user.accounts.find(params[:account_id])
    mapping = params[:mapping]&.to_unsafe_h || {}

    service = build_service(file_type, file_content, current_user, account: account, mapping: mapping)
    @result = service.import!

    # Send push notification for import completion
    PushNotificationService.import_complete(current_user, @result, filename || "file")

    parts = [ "Imported #{@result[:imported]} transactions" ]
    parts << "#{@result[:duplicates]} duplicates skipped" if @result[:duplicates].to_i > 0
    parts << "#{@result[:skipped] - @result[:duplicates].to_i} rows skipped" if @result[:skipped].to_i > @result[:duplicates].to_i

    format_label = file_type&.delete(".")&.upcase || "file"

    if @result[:errors].any?
      error_summary = @result[:errors].first(5).join("; ")
      error_summary += " (and #{@result[:errors].size - 5} more)" if @result[:errors].size > 5
      redirect_to transactions_path, notice: "#{parts.join(', ')}. #{error_summary}"
    else
      redirect_to transactions_path, notice: "#{parts.join(', ')} from #{filename || format_label}."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to new_import_path, alert: "Selected account not found. Please try again."
  end

  private

  def detect_file_extension(file)
    ext = File.extname(file.original_filename).downcase
    return ext if ACCEPTED_EXTENSIONS.include?(ext)

    # Fallback: detect by content type
    case file.content_type
    when "text/csv", "application/csv"
      ".csv"
    when "application/x-ofx", "application/ofx"
      ".ofx"
    when "application/qif", "application/x-qif"
      ".qif"
    when "application/pdf"
      ".pdf"
    else
      ext
    end
  end

  def build_service(file_type, content, user, account: nil, mapping: {})
    case file_type
    when ".csv"
      CsvImportService.new(content, user, account: account, mapping: mapping)
    when ".ofx", ".qfx"
      OfxImportService.new(content, user, account: account, mapping: mapping)
    when ".qif"
      QifImportService.new(content, user, account: account, mapping: mapping)
    when ".pdf"
      PdfImportService.new(content, user, account: account, mapping: mapping)
    else
      raise ArgumentError, "Unsupported file type: #{file_type}"
    end
  end
end
