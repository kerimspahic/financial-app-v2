class TablePreferencesController < ApplicationController
  def update
    page_key = params[:page_key]
    visible_columns = params[:visible_columns]

    pref = current_user.preference
    settings = pref.table_settings || {}
    settings[page_key] = { "visible_columns" => visible_columns }
    pref.update!(table_settings: settings)

    head :ok
  end
end
