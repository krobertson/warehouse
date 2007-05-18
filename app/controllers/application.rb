# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :repository
  before_filter { |c| c.repository.sync_revisions }

  def repository
    @repository ||= Repository.find(1)
  end
end
