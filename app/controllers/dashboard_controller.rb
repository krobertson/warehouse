class DashboardController < ApplicationController
  skip_before_filter :check_for_repository

  def index
    redirect_to browser_path
  end
end
