class BillsController < ApplicationController
  include BalanceUpdatable
  require_permission "manage_bills"

  before_action :set_bill, only: [ :show, :edit, :update, :destroy, :pay ]

  def index
    bills = current_user.bills.active.includes(:category, :account, :bill_payments)

    grouped = bills.group_by(&:status)
    @overdue_bills = grouped[:overdue] || []
    @due_soon_bills = grouped[:due_soon] || []
    @upcoming_bills = grouped[:upcoming] || []
    @paid_bills = grouped[:paid] || []

    @total_monthly = bills.sum { |b| b.monthly? ? b.amount : b.annual_cost / 12.0 }
    @total_annual = bills.sum(&:annual_cost)
    @overdue_count = @overdue_bills.size
  end

  def show
    @payments = @bill.bill_payments.order(paid_date: :desc).limit(10)
  end

  def new
    @bill = current_user.bills.build(
      due_date: Date.current,
      frequency: :monthly,
      reminder_days_before: 3
    )
  end

  def create
    @bill = current_user.bills.build(bill_params)
    if @bill.save
      redirect_to bills_path, notice: "Bill was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @bill.update(bill_params)
      redirect_to bills_path, notice: "Bill was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bill.destroy
    redirect_to bills_path, notice: "Bill was successfully deleted."
  end

  def pay
    ActiveRecord::Base.transaction do
      payment = @bill.bill_payments.create!(
        amount: @bill.amount,
        paid_date: Date.current
      )

      if @bill.account.present? && @bill.category.present?
        transaction = current_user.transactions.build(
          description: "Bill payment: #{@bill.name}",
          amount: @bill.amount,
          transaction_type: :expense,
          date: Date.current,
          account: @bill.account,
          category: @bill.category
        )
        if transaction.save
          payment.update!(linked_transaction: transaction)
          update_account_balance(transaction)
        end
      end
    end

    redirect_to bills_path, notice: "#{@bill.name} marked as paid."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to bills_path, alert: "Failed to record payment: #{e.message}"
  end

  private

  def set_bill
    @bill = current_user.bills.find(params[:id])
  end

  def bill_params
    params.expect(bill: [ :name, :amount, :due_date, :frequency, :category_id, :account_id,
                          :reminder_days_before, :auto_pay, :website_url, :notes, :active ])
  end
end
