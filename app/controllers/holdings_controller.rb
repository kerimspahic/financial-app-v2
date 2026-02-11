class HoldingsController < ApplicationController
  require_permission "manage_accounts"
  before_action :set_account
  before_action :set_holding, only: [ :edit, :update, :destroy ]

  def index
    @holdings = @account.holdings.ordered
    @total_value = @holdings.sum(&:display_value)
    @total_cost_basis = @holdings.sum(&:total_cost_basis)
    @total_gain_loss = @holdings.sum { |h| h.unrealized_gain_loss || 0 }
    @total_return_percent = @total_cost_basis.positive? ? ((@total_gain_loss / @total_cost_basis) * 100).round(2) : 0

    @allocation_data = {
      labels: @holdings.map(&:symbol),
      datasets: [ {
        data: @holdings.map { |h| h.display_value.to_f },
        backgroundColor: generate_colors(@holdings.size),
        borderWidth: 0,
        hoverOffset: 8
      } ]
    }
  end

  def new
    @holding = @account.holdings.build
  end

  def create
    @holding = @account.holdings.build(holding_params)
    if @holding.save
      redirect_to account_holdings_path(@account), notice: "Holding added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @holding.update(holding_params)
      redirect_to account_holdings_path(@account), notice: "Holding updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @holding.destroy
    redirect_to account_holdings_path(@account), notice: "Holding removed."
  end

  private

  def set_account
    @account = current_user.accounts.find(params[:account_id])
  end

  def set_holding
    @holding = @account.holdings.find(params[:id])
  end

  def holding_params
    params.expect(holding: [ :symbol, :name, :holding_type, :shares, :cost_basis_per_share, :current_price ])
  end

  def generate_colors(count)
    palette = [
      "rgba(59, 130, 246, 0.8)", "rgba(16, 185, 129, 0.8)", "rgba(245, 158, 11, 0.8)",
      "rgba(239, 68, 68, 0.8)", "rgba(139, 92, 246, 0.8)", "rgba(236, 72, 153, 0.8)",
      "rgba(6, 182, 212, 0.8)", "rgba(99, 102, 241, 0.8)", "rgba(20, 184, 166, 0.8)"
    ]
    palette.cycle.take(count)
  end
end
