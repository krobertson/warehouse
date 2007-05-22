class DashboardController < ApplicationController
  skip_before_filter :check_for_repository

  def index
    if Warehouse.multiple_repositories
      render :text => 'unfinished dashboard'
    else
      redirect_to browser_path
    end
  end
end
