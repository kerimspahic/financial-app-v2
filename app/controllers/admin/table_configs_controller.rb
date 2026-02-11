module Admin
  class TableConfigsController < BaseController
    before_action -> { set_section(:table_configs) }
    before_action :set_table_config, only: [ :edit, :update ]

    def index
      @table_configs = TableConfig.order(:page_key)
    end

    def edit
    end

    def update
      if @table_config.update(table_config_params)
        redirect_to admin_table_configs_path, notice: "Table configuration updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_table_config
      @table_config = TableConfig.find(params[:id])
    end

    def table_config_params
      columns = parse_json_param(:columns)
      search_fields = params[:table_config]&.dig(:search_fields) || []
      filters = parse_json_param(:filters)

      { columns: columns, search_fields: search_fields, filters: filters }
    end

    def parse_json_param(key)
      raw = params[:table_config]&.dig(key)
      return [] unless raw

      if raw.is_a?(String)
        JSON.parse(raw)
      elsif raw.is_a?(ActionController::Parameters)
        raw.values.map { |item| item.is_a?(ActionController::Parameters) ? item.to_unsafe_h : item }
      elsif raw.is_a?(Array)
        raw.map { |item| item.is_a?(ActionController::Parameters) ? item.to_unsafe_h : item }
      else
        []
      end
    rescue JSON::ParserError
      []
    end
  end
end
