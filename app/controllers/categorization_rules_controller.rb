class CategorizationRulesController < ApplicationController
  require_permission "manage_categories"
  before_action :set_categorization_rule, only: [ :edit, :update, :destroy, :toggle ]

  def index
    @categorization_rules = current_user.categorization_rules.includes(:category).ordered
    @categories = current_user.categories.order(:name)
  end

  def new
    @categorization_rule = current_user.categorization_rules.build(priority: 0, match_field: :description)
    load_form_data
  end

  def create
    @categorization_rule = current_user.categorization_rules.build(rule_params)
    parse_actions_from_params
    if @categorization_rule.save
      redirect_to categorization_rules_path, notice: "Categorization rule was successfully created."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_data
  end

  def update
    @categorization_rule.assign_attributes(rule_params)
    parse_actions_from_params
    if @categorization_rule.save
      redirect_to categorization_rules_path, notice: "Categorization rule was successfully updated."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @categorization_rule.destroy
    redirect_to categorization_rules_path, notice: "Categorization rule was successfully deleted."
  end

  def toggle
    @categorization_rule.update!(active: !@categorization_rule.active)
    status = @categorization_rule.active? ? "activated" : "deactivated"
    redirect_to categorization_rules_path, notice: "Rule '#{@categorization_rule.pattern}' #{status}."
  end

  private

  def set_categorization_rule
    @categorization_rule = current_user.categorization_rules.find(params[:id])
  end

  def rule_params
    params.expect(categorization_rule: [ :pattern, :match_type, :match_field, :category_id, :priority, :active ])
  end

  def parse_actions_from_params
    actions_data = params.dig(:categorization_rule, :actions_data)
    return if actions_data.blank?

    begin
      parsed = JSON.parse(actions_data)
      @categorization_rule.actions = parsed.select { |a| a["type"].present? }
    rescue JSON::ParserError
      @categorization_rule.actions = []
    end
  end

  def load_form_data
    @categories = current_user.categories.order(:name)
    @tags = current_user.tags.order(:name)
  end
end
