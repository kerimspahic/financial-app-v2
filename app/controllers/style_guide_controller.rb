class StyleGuideController < ApplicationController
  skip_before_action :authenticate_user! if Rails.env.development?

  def index
  end
end
