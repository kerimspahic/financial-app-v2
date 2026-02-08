module Admin
  class BaseController < ApplicationController
    include AdminAuthorizable
  end
end
