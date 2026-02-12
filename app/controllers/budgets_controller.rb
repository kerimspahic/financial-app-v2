class BudgetsController < ApplicationController
  require_permission "manage_budgets"
  before_action :set_budget, only: [ :edit, :update, :destroy, :transactions ]

  def index
    @month = (params[:month] || Date.current.month).to_i
    @year = (params[:year] || Date.current.year).to_i
    @budgets = current_user.budgets.where(month: @month, year: @year).includes(:category)
  end

  def new
    @budget = current_user.budgets.build(month: Date.current.month, year: Date.current.year)
  end

  def create
    @budget = current_user.budgets.build(budget_params)
    if @budget.save
      redirect_to budgets_path, notice: "Budget was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @budget.update(budget_params)
      redirect_to budgets_path, notice: "Budget was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @budget.destroy
    redirect_to budgets_path, notice: "Budget was successfully deleted."
  end

  def transactions
    @transactions = current_user.transactions
      .expense
      .where(category_id: @budget.category_id)
      .by_month(@budget.month, @budget.year)
      .includes(:account, :category)
      .order(date: :desc)
  end

  private

  def set_budget
    @budget = current_user.budgets.find(params[:id])
  end

  def budget_params
    params.expect(budget: [ :amount, :month, :year, :category_id ])
  end
end
