class PayeesController < ApplicationController
  require_permission "manage_transactions"

  def index
    @payees = Transaction.distinct_payees(current_user)
    @total_payees = @payees.length
  end

  # POST /payees/merge
  # Merge multiple payees into a single target payee name
  def merge
    source_payees = params[:source_payees] || []
    target_payee = params[:target_payee]&.strip

    if source_payees.empty? || target_payee.blank?
      redirect_to payees_path, alert: "Please select payees to merge and provide a target name."
      return
    end

    count = current_user.transactions
      .where(payee: source_payees)
      .update_all(payee: target_payee)

    redirect_to payees_path, notice: "Successfully merged #{source_payees.size} payees into '#{target_payee}' (#{count} transactions updated)."
  end

  # PATCH /payees/update_all
  # Rename a payee across all transactions
  def update_all
    old_payee = params[:old_payee]&.strip
    new_payee = params[:new_payee]&.strip

    if old_payee.blank? || new_payee.blank?
      redirect_to payees_path, alert: "Both old and new payee names are required."
      return
    end

    count = current_user.transactions
      .where(payee: old_payee)
      .update_all(payee: new_payee)

    redirect_to payees_path, notice: "Renamed '#{old_payee}' to '#{new_payee}' (#{count} transactions updated)."
  end
end
