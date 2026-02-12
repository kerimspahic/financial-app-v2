class SmartCategorizationService
  MIN_CONFIDENCE = 0.3

  Result = Struct.new(:category_id, :category_name, :confidence, :method, keyword_init: true)

  def initialize(user, transaction)
    @user = user
    @transaction = transaction
  end

  # Suggest a category based on historical data
  # Returns a Result or nil
  def suggest
    # Strategy 1: Same payee -> most common category
    result = suggest_by_payee
    return result if result && result.confidence >= MIN_CONFIDENCE

    # Strategy 2: Similar description -> most common category
    result = suggest_by_description_similarity
    return result if result && result.confidence >= MIN_CONFIDENCE

    nil
  end

  private

  # Find past transactions with the same payee and return the most common category
  def suggest_by_payee
    return nil if @transaction.payee.blank?

    past_transactions = @user.transactions
      .where(payee: @transaction.payee)
      .where.not(category_id: nil)
      .where.not(id: @transaction.id)

    total_count = past_transactions.count
    return nil if total_count.zero?

    # Group by category and find the most common
    category_counts = past_transactions
      .group(:category_id)
      .count
      .sort_by { |_id, count| -count }

    top_category_id, top_count = category_counts.first
    return nil unless top_category_id

    category = @user.categories.find_by(id: top_category_id)
    return nil unless category

    # Confidence: proportion of transactions using this category
    # Boosted because payee is an exact match
    raw_confidence = top_count.to_f / total_count
    confidence = [ (raw_confidence * 0.9 + 0.1), 1.0 ].min # Floor at 0.1, payee match is strong

    Result.new(
      category_id: category.id,
      category_name: category.name,
      confidence: confidence.round(2),
      method: :payee_history
    )
  end

  # Find past transactions with similar descriptions and return the most common category
  def suggest_by_description_similarity
    return nil if @transaction.description.blank?

    # Extract significant words from description (3+ chars, not common words)
    words = extract_keywords(@transaction.description)
    return nil if words.empty?

    # Build a LIKE query for each word
    conditions = words.map { "LOWER(description) LIKE ?" }
    values = words.map { |w| "%#{sanitize_like(w)}%" }

    past_transactions = @user.transactions
      .where(conditions.join(" OR "), *values)
      .where.not(category_id: nil)
      .where.not(id: @transaction.id)

    total_count = past_transactions.count
    return nil if total_count.zero?

    category_counts = past_transactions
      .group(:category_id)
      .count
      .sort_by { |_id, count| -count }

    top_category_id, top_count = category_counts.first
    return nil unless top_category_id

    category = @user.categories.find_by(id: top_category_id)
    return nil unless category

    # Confidence: proportion of matches, with a lower base since it is fuzzy matching
    raw_confidence = top_count.to_f / total_count
    confidence = [ raw_confidence * 0.7, 1.0 ].min # Cap lower than payee match

    Result.new(
      category_id: category.id,
      category_name: category.name,
      confidence: confidence.round(2),
      method: :description_similarity
    )
  end

  def extract_keywords(text)
    stop_words = %w[the a an and or but in on at to for of is it this that with from by]
    text.downcase
      .gsub(/[^a-z0-9\s]/, "")
      .split(/\s+/)
      .reject { |w| w.length < 3 || stop_words.include?(w) }
      .uniq
      .first(5) # Limit to 5 keywords to avoid overly broad queries
  end

  def sanitize_like(string)
    string.gsub(/[%_\\]/) { |m| "\\#{m}" }
  end
end
