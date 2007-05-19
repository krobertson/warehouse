class DashboardController < ApplicationController
  def index
    redirect_to browser_path
  end
end
