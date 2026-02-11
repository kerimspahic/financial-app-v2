class SavingsGoalsController < ApplicationController
  require_permission "manage_savings_goals"
  before_action :set_savings_goal, only: [ :show, :edit, :update, :destroy, :contribute, :remove_contribution ]

  def index
    @savings_goals = current_user.savings_goals.includes(:savings_contributions, :account).order(created_at: :desc)

    @total_saved = @savings_goals.sum(&:current_amount)
    @total_target = @savings_goals.sum(&:target_amount)
    @overall_percentage = @total_target.positive? ? [ (@total_saved / @total_target * 100).round(1), 100 ].min : 0
  end

  def show
    @contributions = @savings_goal.savings_contributions.order(date: :desc)
  end

  def new
    @savings_goal = current_user.savings_goals.build(color: "#10b981")
  end

  def create
    @savings_goal = current_user.savings_goals.build(savings_goal_params)
    if @savings_goal.save
      redirect_to savings_goals_path, notice: "Savings goal was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @savings_goal.update(savings_goal_params)
      redirect_to savings_goals_path, notice: "Savings goal was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @savings_goal.destroy
    redirect_to savings_goals_path, notice: "Savings goal was successfully deleted."
  end

  def contribute
    contribution = @savings_goal.savings_contributions.build(contribution_params)
    if contribution.save
      @savings_goal.update!(current_amount: @savings_goal.current_amount + contribution.amount)
      redirect_to savings_goal_path(@savings_goal), notice: "Contribution added successfully."
    else
      redirect_to savings_goal_path(@savings_goal), alert: "Failed to add contribution: #{contribution.errors.full_messages.join(', ')}"
    end
  end

  def remove_contribution
    contribution = @savings_goal.savings_contributions.find(params[:contribution_id])
    @savings_goal.update!(current_amount: [ @savings_goal.current_amount - contribution.amount, 0 ].max)
    contribution.destroy
    redirect_to savings_goal_path(@savings_goal), notice: "Contribution removed successfully."
  end

  private

  def set_savings_goal
    @savings_goal = current_user.savings_goals.find(params[:id])
  end

  def savings_goal_params
    params.expect(savings_goal: [ :name, :target_amount, :deadline, :color, :icon, :account_id ])
  end

  def contribution_params
    params.expect(savings_contribution: [ :amount, :date, :note ])
  end
end
