class CategorizationRulesController < ApplicationController
  require_permission "manage_categories"
  before_action :set_categorization_rule, only: [ :edit, :update, :destroy ]

  def index
    @categorization_rules = current_user.categorization_rules.includes(:category).ordered
    @categories = current_user.categories.order(:name)
  end

  def new
    @categorization_rule = current_user.categorization_rules.build(priority: 0)
  end

  def create
    @categorization_rule = current_user.categorization_rules.build(rule_params)
    if @categorization_rule.save
      redirect_to categorization_rules_path, notice: "Categorization rule was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @categorization_rule.update(rule_params)
      redirect_to categorization_rules_path, notice: "Categorization rule was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @categorization_rule.destroy
    redirect_to categorization_rules_path, notice: "Categorization rule was successfully deleted."
  end

  private

  def set_categorization_rule
    @categorization_rule = current_user.categorization_rules.find(params[:id])
  end

  def rule_params
    params.expect(categorization_rule: [ :pattern, :match_type, :category_id, :priority ])
  end
end
