class Benchmark < ApplicationRecord
  validates :name, presence: true

  def cumulative_return(start_month, end_month)
    relevant = monthly_returns.select { |k, _| k >= start_month && k <= end_month }
    return 0 if relevant.empty?
    relevant.values.reduce(1.0) { |acc, r| acc * (1 + r / 100.0) }
  end
end
