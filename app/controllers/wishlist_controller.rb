class WishlistController < ApplicationController
  require_permission "manage_wishlist"

  def index
  end
end
