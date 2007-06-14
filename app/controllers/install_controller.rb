class InstallController < ApplicationController
  skip_before_filter :check_for_repository

  def index
    redirect_to root_path if current_repository
  end
end
