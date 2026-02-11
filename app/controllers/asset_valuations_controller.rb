class AssetValuationsController < ApplicationController
  require_permission "manage_accounts"
  before_action :set_account

  def index
    @valuations = @account.asset_valuations.recent
    @chart_data = {
      labels: @valuations.reverse.map { |v| v.date.strftime("%b %Y") },
      datasets: [ {
        label: "Value",
        data: @valuations.reverse.map { |v| v.value.to_f },
        borderColor: "rgb(var(--color-primary-500))",
        backgroundColor: "rgba(var(--color-primary-500), 0.1)",
        fill: true,
        tension: 0.3
      } ]
    }
  end

  def new
    @valuation = @account.asset_valuations.build(date: Date.current)
  end

  def create
    @valuation = @account.asset_valuations.build(valuation_params)
    if @valuation.save
      redirect_to account_asset_valuations_path(@account), notice: "Valuation recorded."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @account.asset_valuations.find(params[:id]).destroy
    redirect_to account_asset_valuations_path(@account), notice: "Valuation removed."
  end

  private

  def set_account
    @account = current_user.accounts.find(params[:account_id])
  end

  def valuation_params
    params.expect(asset_valuation: [ :value, :date, :source, :notes ])
  end
end
