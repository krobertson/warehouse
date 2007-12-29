class DashboardController < ApplicationController
  skip_before_filter :check_for_repository

  def index
    redirect_to(repository_subdomain.blank? ? hosted_url(logged_in? ? :changesets : :public_changesets) : hosted_url(:browser))
  end
end
