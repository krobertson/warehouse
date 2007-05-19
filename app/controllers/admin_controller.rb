class AdminController < ApplicationController
  def index
    @repos = Repository.find(:all)
  end
  
  def update
    
  end
  
  protected
    def admin_required
      admin? || access_denied
    end
end
