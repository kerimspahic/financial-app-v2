class CurrencyConversionService
  # Converts an amount from one currency to another using the ExchangeRateService.
  # Returns a hash with :converted_amount and :rate.
  #
  # Falls back to 1.0 rate if currencies are the same.
  # Uses the exchange_conversions table history via ExchangeRateService for live rates.
  #
  # @param amount [Numeric] the amount to convert
  # @param from_currency [String] 3-letter currency code (e.g., "EUR")
  # @param to_currency [String] 3-letter currency code (e.g., "USD")
  # @param date [Date] the date for the conversion (reserved for future historical rate support)
  # @return [Hash] { converted_amount: BigDecimal, rate: Float }
  def self.convert(amount, from_currency, to_currency, date: Date.current)
    return { converted_amount: BigDecimal(amount.to_s), rate: 1.0 } if from_currency == to_currency

    result = ExchangeRateService.convert(
      amount: amount,
      from: from_currency,
      to: to_currency
    )

    { converted_amount: result[:converted_amount], rate: result[:rate] }
  rescue ExchangeRateService::ApiError => e
    Rails.logger.error("CurrencyConversionService error: #{e.message}")
    raise
  end
end
