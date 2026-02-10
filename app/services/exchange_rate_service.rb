require "net/http"

class ExchangeRateService
  PROVIDERS = {
    "fawazahmed0" => {
      name: "fawazahmed0/exchange-api",
      description: "340+ currencies, CDN-hosted, community-maintained"
    },
    "frankfurter" => {
      name: "Frankfurter (ECB)",
      description: "30 currencies, European Central Bank data"
    }
  }.freeze

  CACHE_TTL = 1.hour

  class ApiError < StandardError; end

  def self.rate(from:, to:)
    return 1.0 if from == to

    rates = latest_rates(from)
    rates[to] || raise(ApiError, "Rate not found for #{from} -> #{to}")
  end

  def self.convert(amount:, from:, to:)
    rate = rate(from: from, to: to)
    converted = (BigDecimal(amount.to_s) * BigDecimal(rate.to_s)).round(4)
    { converted_amount: converted, rate: rate }
  end

  def self.latest_rates(base_currency)
    cache_key = "exchange_rates/#{base_currency}"

    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      fetch_with_fallback(base_currency)
    end
  end

  def self.current_provider
    AppSetting.get("exchange_rate_provider", default: "fawazahmed0")
  end

  def self.provider_info
    PROVIDERS[current_provider] || PROVIDERS["fawazahmed0"]
  end

  def self.last_updated_at
    Rails.cache.read("exchange_rates/last_updated")
  end

  def self.last_provider_used
    Rails.cache.read("exchange_rates/last_provider")
  end

  def self.provider_last_updated_at(provider_key)
    Rails.cache.read("exchange_rates/provider_updated/#{provider_key}")
  end

  # Private methods

  def self.fetch_with_fallback(base_currency)
    provider = current_provider
    primary = provider == "frankfurter" ? :fetch_frankfurter : :fetch_fawazahmed0
    fallback = provider == "frankfurter" ? :fetch_fawazahmed0 : :fetch_frankfurter

    begin
      rates = send(primary, base_currency)
      record_update(provider)
      rates
    rescue ApiError => e
      Rails.logger.warn("Primary provider (#{provider}) failed: #{e.message}. Trying fallback...")
      fallback_name = provider == "frankfurter" ? "fawazahmed0" : "frankfurter"
      begin
        rates = send(fallback, base_currency)
        record_update(fallback_name)
        rates
      rescue ApiError => fallback_error
        raise ApiError, "Both providers failed. Primary: #{e.message}. Fallback: #{fallback_error.message}"
      end
    end
  end

  private_class_method def self.fetch_fawazahmed0(base_currency)
    code = base_currency.downcase
    uri = URI("https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/#{code}.json")
    response = Net::HTTP.get_response(uri)

    unless response.is_a?(Net::HTTPSuccess)
      raise ApiError, "fawazahmed0 API error: #{response.code} #{response.message}"
    end

    data = JSON.parse(response.body)
    raw_rates = data[code]

    unless raw_rates.is_a?(Hash)
      raise ApiError, "fawazahmed0: unexpected response format for #{base_currency}"
    end

    # Convert lowercase keys to uppercase and filter to 3-letter alpha codes only
    raw_rates.each_with_object({}) do |(key, value), result|
      next unless key.match?(/\A[a-z]{3}\z/)
      result[key.upcase] = value.to_f
    end
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError => e
    raise ApiError, "Could not connect to fawazahmed0: #{e.message}"
  end

  private_class_method def self.fetch_frankfurter(base_currency)
    uri = URI("https://api.frankfurter.dev/v1/latest?base=#{base_currency}")
    response = Net::HTTP.get_response(uri)

    unless response.is_a?(Net::HTTPSuccess)
      raise ApiError, "Frankfurter API error: #{response.code} #{response.message}"
    end

    data = JSON.parse(response.body)
    data["rates"]
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError => e
    raise ApiError, "Could not connect to Frankfurter: #{e.message}"
  end

  private_class_method def self.record_update(provider_name)
    now = Time.current
    Rails.cache.write("exchange_rates/last_updated", now, expires_in: CACHE_TTL)
    Rails.cache.write("exchange_rates/last_provider", provider_name, expires_in: CACHE_TTL)
    Rails.cache.write("exchange_rates/provider_updated/#{provider_name}", now, expires_in: CACHE_TTL)
  end
end
