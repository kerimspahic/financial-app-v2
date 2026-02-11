class ImportsController < ApplicationController
  require_permission "manage_imports"

  def new
    @accounts = current_user.accounts.active.order(:name)
  end

  def preview
    file = params[:file]

    if file.blank?
      redirect_to new_import_path, alert: "Please select a CSV file."
      return
    end

    unless file.content_type.in?(%w[text/csv application/csv text/plain application/vnd.ms-excel])
      redirect_to new_import_path, alert: "Invalid file type. Please upload a CSV file."
      return
    end

    csv_content = file.read.force_encoding("UTF-8")
    csv_content = csv_content.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

    session[:csv_import_content] = csv_content
    session[:csv_import_filename] = file.original_filename

    begin
      @service = CsvImportService.new(csv_content, current_user)
      @headers = @service.headers
      @column_mapping = @service.column_mapping
      @preview_rows = @service.preview_rows
      @accounts = current_user.accounts.active.order(:name)
      @categories = current_user.categories.order(:name)
      @filename = file.original_filename
      @total_rows = @service.rows.size
    rescue ArgumentError => e
      redirect_to new_import_path, alert: e.message
    end
  end

  def create
    csv_content = session.delete(:csv_import_content)
    filename = session.delete(:csv_import_filename)

    if csv_content.blank?
      redirect_to new_import_path, alert: "Import session expired. Please upload again."
      return
    end

    account = current_user.accounts.find(params[:account_id])
    mapping = params[:mapping]&.to_unsafe_h || {}

    service = CsvImportService.new(csv_content, current_user, account: account, mapping: mapping)
    @result = service.import!

    if @result[:errors].any?
      error_summary = @result[:errors].first(5).join("; ")
      error_summary += " (and #{@result[:errors].size - 5} more)" if @result[:errors].size > 5
      redirect_to transactions_path, notice: "Imported #{@result[:imported]} transactions (#{@result[:skipped]} skipped). #{error_summary}"
    else
      redirect_to transactions_path, notice: "Successfully imported #{@result[:imported]} transactions from #{filename || 'CSV'}."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to new_import_path, alert: "Selected account not found. Please try again."
  end
end
