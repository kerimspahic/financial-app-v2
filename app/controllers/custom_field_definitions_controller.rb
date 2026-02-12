class CustomFieldDefinitionsController < ApplicationController
  before_action :set_custom_field_definition, only: [ :update, :destroy ]

  def index
    @custom_field_definitions = current_user.custom_field_definitions.ordered
    @custom_field_definition = CustomFieldDefinition.new
  end

  def create
    @custom_field_definition = current_user.custom_field_definitions.build(custom_field_definition_params)

    if @custom_field_definition.save
      redirect_to custom_field_definitions_path, notice: "Custom field created."
    else
      @custom_field_definitions = current_user.custom_field_definitions.ordered
      render :index, status: :unprocessable_entity
    end
  end

  def update
    if @custom_field_definition.update(custom_field_definition_params)
      redirect_to custom_field_definitions_path, notice: "Custom field updated."
    else
      @custom_field_definitions = current_user.custom_field_definitions.ordered
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @custom_field_definition.destroy
    redirect_to custom_field_definitions_path, notice: "Custom field deleted."
  end

  private

  def set_custom_field_definition
    @custom_field_definition = current_user.custom_field_definitions.find(params[:id])
  end

  def custom_field_definition_params
    params.expect(custom_field_definition: [ :name, :field_type, :position, options: {} ])
  end
end
