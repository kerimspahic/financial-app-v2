class ExchangesController < ApplicationController
  require_permission "manage_exchanges"

  def index
    @from_currency = params[:from_currency] || "USD"
    @to_currency = params[:to_currency] || "EUR"
    @amount = params[:amount].present? ? params[:amount].to_f : 1.0

    begin
      result = ExchangeRateService.convert(
        amount: @amount,
        from: @from_currency,
        to: @to_currency
      )
      @converted_amount = result[:converted_amount]
      @exchange_rate = result[:rate]
    rescue ExchangeRateService::ApiError => e
      @rate_error = e.message
    end

    @provider_name = ExchangeRateService.provider_info[:name]
    @last_updated_at = ExchangeRateService.last_updated_at
    last_provider = ExchangeRateService.last_provider_used
    @last_provider_name = last_provider ? (ExchangeRateService::PROVIDERS.dig(last_provider, :name) || last_provider) : nil

    @pagy, @conversions = pagy(
      current_user.exchange_conversions.recent,
      limit: user_per_page
    )
  end

  def create
    from_currency = conversion_params[:from_currency]
    to_currency = conversion_params[:to_currency]
    from_amount = conversion_params[:from_amount].to_f

    begin
      result = ExchangeRateService.convert(
        amount: from_amount,
        from: from_currency,
        to: to_currency
      )

      @conversion = current_user.exchange_conversions.build(
        from_currency: from_currency,
        to_currency: to_currency,
        from_amount: from_amount,
        to_amount: result[:converted_amount],
        exchange_rate: result[:rate],
        converted_at: Time.current
      )

      if @conversion.save
        redirect_to exchanges_path, notice: "Conversion saved to history."
      else
        redirect_to exchanges_path, alert: @conversion.errors.full_messages.join(", ")
      end
    rescue ExchangeRateService::ApiError => e
      redirect_to exchanges_path, alert: "Exchange rate error: #{e.message}"
    end
  end

  def destroy
    @conversion = current_user.exchange_conversions.find(params[:id])
    @conversion.destroy
    redirect_to exchanges_path, notice: "Conversion removed from history."
  end

  def rate
    from = params[:from]
    to = params[:to]
    amount = (params[:amount] || 1).to_f

    result = ExchangeRateService.convert(amount: amount, from: from, to: to)
    last_updated = ExchangeRateService.last_updated_at
    last_provider = ExchangeRateService.last_provider_used
    render json: {
      from: from,
      to: to,
      amount: amount,
      converted_amount: result[:converted_amount].to_f,
      rate: result[:rate].to_f,
      provider: last_provider ? (ExchangeRateService::PROVIDERS.dig(last_provider, :name) || last_provider) : nil,
      last_updated: last_updated&.iso8601
    }
  rescue ExchangeRateService::ApiError => e
    render json: { error: e.message }, status: :service_unavailable
  end

  private

  def conversion_params
    params.expect(exchange_conversion: [ :from_currency, :to_currency, :from_amount ])
  end
end
