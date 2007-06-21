class DashboardController < ApplicationController
  skip_before_filter :check_for_repository

  def index
    redirect_to(repository_subdomain.blank? ? (logged_in? ? changesets_path : public_changesets_path) : browser_path)
  end
end
