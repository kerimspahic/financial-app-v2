class AccountMerger
  attr_reader :errors

  def initialize(source_account, target_account)
    @source = source_account
    @target = target_account
    @errors = []
  end

  def merge!
    validate!
    return false if @errors.any?

    ActiveRecord::Base.transaction do
      @source.transactions.update_all(account_id: @target.id)
      Transaction.where(destination_account_id: @source.id).update_all(destination_account_id: @target.id)

      merge_holdings if @source.respond_to?(:holdings) && @source.holdings.any?

      @source.asset_valuations.update_all(account_id: @target.id) if @source.respond_to?(:asset_valuations)

      SavingsGoal.where(account_id: @source.id).update_all(account_id: @target.id)
      Bill.where(account_id: @source.id).update_all(account_id: @target.id)
      AccountBalanceSnapshot.where(account_id: @source.id).destroy_all

      @target.update!(balance: @target.balance + @source.balance)
      @source.destroy!
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.message
    false
  end

  private

  def validate!
    @errors << "Source and target must be different accounts" if @source.id == @target.id
    @errors << "Both accounts must belong to the same user" if @source.user_id != @target.user_id
    @errors << "Source account not found" unless @source.persisted?
    @errors << "Target account not found" unless @target.persisted?
  end

  def merge_holdings
    @source.holdings.each do |holding|
      existing = @target.holdings.find_by(symbol: holding.symbol)
      if existing
        total_shares = existing.shares + holding.shares
        total_cost = existing.total_cost_basis + holding.total_cost_basis
        existing.update!(shares: total_shares, cost_basis_per_share: total_cost / total_shares)
        holding.destroy
      else
        holding.update!(account_id: @target.id)
      end
    end
  end
end
