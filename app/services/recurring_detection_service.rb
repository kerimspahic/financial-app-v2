class RecurringDetectionService
  AMOUNT_TOLERANCE = 0.10 # +/- 10%
  MIN_OCCURRENCES = 3
  MAX_INTERVAL_VARIANCE_DAYS = 5

  # Recognized interval patterns (in days)
  INTERVAL_PATTERNS = {
    weekly: { target: 7, range: (5..9) },
    biweekly: { target: 14, range: (12..16) },
    monthly: { target: 30, range: (26..35) },
    quarterly: { target: 91, range: (85..97) },
    yearly: { target: 365, range: (350..380) }
  }.freeze

  Result = Struct.new(:payee, :average_amount, :frequency, :interval_days, :occurrence_count,
                      :confidence, :last_date, :next_predicted_date, :transaction_ids, keyword_init: true)

  def initialize(user)
    @user = user
  end

  # Analyze user's transactions and return array of recurring candidates
  def detect
    candidates = []

    payee_groups = group_by_payee
    payee_groups.each do |payee, transactions|
      next if transactions.size < MIN_OCCURRENCES

      # Sub-group by approximate amount (within tolerance)
      amount_groups = group_by_approximate_amount(transactions)

      amount_groups.each do |_amount_key, group_txns|
        next if group_txns.size < MIN_OCCURRENCES

        result = analyze_interval(payee, group_txns)
        candidates << result if result && result.confidence >= 0.4
      end
    end

    candidates.sort_by { |c| -c.confidence }
  end

  private

  def group_by_payee
    @user.transactions
      .where.not(payee: [ nil, "" ])
      .where(transaction_type: [ :expense, :income ])
      .order(:date)
      .group_by(&:payee)
  end

  def group_by_approximate_amount(transactions)
    groups = {}

    transactions.each do |txn|
      amount = txn.amount.to_f
      matched_key = groups.keys.find do |key|
        (amount - key).abs <= key * AMOUNT_TOLERANCE
      end

      if matched_key
        groups[matched_key] << txn
      else
        groups[amount] = [ txn ]
      end
    end

    groups
  end

  def analyze_interval(payee, transactions)
    sorted = transactions.sort_by(&:date)
    dates = sorted.map(&:date)

    # Calculate intervals between consecutive transactions
    intervals = dates.each_cons(2).map { |a, b| (b - a).to_i }
    return nil if intervals.empty?

    avg_interval = intervals.sum.to_f / intervals.size

    # Try to match a known frequency pattern
    frequency, pattern = detect_frequency(avg_interval)
    return nil unless frequency

    # Calculate confidence based on interval consistency
    target_interval = pattern[:target]
    deviations = intervals.map { |i| (i - target_interval).abs }
    avg_deviation = deviations.sum.to_f / deviations.size
    max_deviation = deviations.max

    # Confidence scoring:
    # - High confidence: consistent intervals, many occurrences
    # - Lower confidence: irregular intervals, few occurrences
    consistency_score = [ 1.0 - (avg_deviation.to_f / target_interval), 0.0 ].max
    occurrence_score = [ (sorted.size - MIN_OCCURRENCES + 1).to_f / 5.0, 1.0 ].min
    recency_score = sorted.last.date >= 90.days.ago.to_date ? 1.0 : 0.5

    confidence = (consistency_score * 0.5 + occurrence_score * 0.3 + recency_score * 0.2).round(2)

    # Reject if max deviation is too large
    return nil if max_deviation > MAX_INTERVAL_VARIANCE_DAYS * 3 && frequency != :yearly

    amounts = sorted.map { |t| t.amount.to_f }
    avg_amount = amounts.sum / amounts.size
    last_date = sorted.last.date
    next_predicted = last_date + target_interval.days

    Result.new(
      payee: payee,
      average_amount: avg_amount.round(2),
      frequency: frequency,
      interval_days: target_interval,
      occurrence_count: sorted.size,
      confidence: confidence,
      last_date: last_date,
      next_predicted_date: next_predicted,
      transaction_ids: sorted.map(&:id)
    )
  end

  def detect_frequency(avg_interval)
    INTERVAL_PATTERNS.each do |freq, pattern|
      return [ freq, pattern ] if pattern[:range].cover?(avg_interval.round)
    end
    nil
  end
end
