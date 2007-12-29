class DashboardController < ApplicationController
  skip_before_filter :check_for_repository

  def index
    redirect_to(repository_subdomain.blank? ? send("root_#{logged_in? ? :changesets : :public_changesets}_path") : hosted_url(:browser))
  end
end
