module Admin
  class SettingsController < BaseController
    before_action -> { set_section(:settings) }

    def show
      @exchange_rate_provider = ExchangeRateService.current_provider
      @last_updated_at = ExchangeRateService.last_updated_at
      @last_provider = ExchangeRateService.last_provider_used
      @provider_timestamps = ExchangeRateService::PROVIDERS.keys.index_with do |key|
        ExchangeRateService.provider_last_updated_at(key)
      end
      @search_debounce = AppSetting.get("search_debounce", default: "600").to_i
    end

    def update
      if params[:exchange_rate_provider].present?
        AppSetting.set("exchange_rate_provider", params[:exchange_rate_provider])
        Rails.cache.delete_matched("exchange_rates/*")
      end

      if params[:search_debounce].present?
        AppSetting.set("search_debounce", params[:search_debounce].to_i.clamp(100, 3000).to_s)
      end

      redirect_to admin_settings_path, notice: "System settings saved."
    end
  end
end
