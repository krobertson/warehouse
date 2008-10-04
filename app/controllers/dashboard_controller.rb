class DashboardController < ApplicationController
  skip_before_filter :check_for_repository

  def index
    unless installed?
      install
      return
    end

    unless logged_in?
      @repositories = Repository.find_all_by_public(true)
      if @repositories.length == 0
        redirect_to '/sessions/new'
        return
      end
    end

    @repositories ||= admin? ? Repository.find(:all) : current_user.administered_repositories
    render :layout => 'application'
  end

end
