class SavedFiltersController < ApplicationController
  def create
    page_key = params[:page_key]
    @filter = current_user.saved_filters.build(
      page_key: page_key,
      name: params[:name],
      filter_params: { q: params[:q]&.to_unsafe_h, search: params[:search] }.compact_blank
    )

    if @filter.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "saved_filters",
            partial: "transactions/saved_filters",
            locals: { saved_filters: current_user.saved_filters.for_page(page_key) }
          )
        end
        format.html { redirect_back fallback_location: transactions_path, notice: "Filter saved." }
      end
    else
      redirect_back fallback_location: transactions_path, alert: @filter.errors.full_messages.join(", ")
    end
  end

  def destroy
    @filter = current_user.saved_filters.find_by(id: params[:id])
    page_key = @filter&.page_key || "transactions"
    @filter&.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "saved_filters",
          partial: "transactions/saved_filters",
          locals: { saved_filters: current_user.saved_filters.for_page(page_key) }
        )
      end
      format.html { redirect_back fallback_location: transactions_path, notice: "Filter deleted." }
    end
  end
end
