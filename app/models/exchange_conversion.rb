class ExchangeConversion < ApplicationRecord
  belongs_to :user

  validates :from_currency, presence: true, length: { is: 3 }
  validates :to_currency, presence: true, length: { is: 3 }
  validates :from_amount, presence: true, numericality: { greater_than: 0 }
  validates :to_amount, presence: true, numericality: { greater_than: 0 }
  validates :exchange_rate, presence: true, numericality: { greater_than: 0 }
  validates :converted_at, presence: true
  validate :currencies_must_differ

  scope :recent, -> { order(converted_at: :desc) }

  SUPPORTED_CURRENCIES = {
    "AED" => "UAE Dirham",
    "ARS" => "Argentine Peso",
    "AUD" => "Australian Dollar",
    "BAM" => "Bosnia-Herzegovina Mark",
    "BGN" => "Bulgarian Lev",
    "BRL" => "Brazilian Real",
    "CAD" => "Canadian Dollar",
    "CHF" => "Swiss Franc",
    "CLP" => "Chilean Peso",
    "CNY" => "Chinese Yuan",
    "COP" => "Colombian Peso",
    "CZK" => "Czech Koruna",
    "DKK" => "Danish Krone",
    "EGP" => "Egyptian Pound",
    "EUR" => "Euro",
    "GBP" => "British Pound",
    "GEL" => "Georgian Lari",
    "HKD" => "Hong Kong Dollar",
    "HRK" => "Croatian Kuna",
    "HUF" => "Hungarian Forint",
    "IDR" => "Indonesian Rupiah",
    "ILS" => "Israeli Shekel",
    "INR" => "Indian Rupee",
    "ISK" => "Icelandic Krona",
    "JPY" => "Japanese Yen",
    "KRW" => "South Korean Won",
    "KWD" => "Kuwaiti Dinar",
    "MAD" => "Moroccan Dirham",
    "MKD" => "Macedonian Denar",
    "MXN" => "Mexican Peso",
    "MYR" => "Malaysian Ringgit",
    "NGN" => "Nigerian Naira",
    "NOK" => "Norwegian Krone",
    "NZD" => "New Zealand Dollar",
    "PEN" => "Peruvian Sol",
    "PHP" => "Philippine Peso",
    "PKR" => "Pakistani Rupee",
    "PLN" => "Polish Zloty",
    "QAR" => "Qatari Riyal",
    "RON" => "Romanian Leu",
    "RSD" => "Serbian Dinar",
    "RUB" => "Russian Ruble",
    "SAR" => "Saudi Riyal",
    "SEK" => "Swedish Krona",
    "SGD" => "Singapore Dollar",
    "THB" => "Thai Baht",
    "TRY" => "Turkish Lira",
    "TWD" => "Taiwan Dollar",
    "UAH" => "Ukrainian Hryvnia",
    "USD" => "US Dollar",
    "UYU" => "Uruguayan Peso",
    "VND" => "Vietnamese Dong",
    "ZAR" => "South African Rand"
  }.freeze

  def self.currency_options
    SUPPORTED_CURRENCIES.map { |code, name| [ "#{code} - #{name}", code ] }
  end

  def formatted_from
    "#{from_amount} #{from_currency}"
  end

  def formatted_to
    "#{to_amount} #{to_currency}"
  end

  private

  def currencies_must_differ
    if from_currency.present? && to_currency.present? && from_currency == to_currency
      errors.add(:to_currency, "must differ from source currency")
    end
  end
end
