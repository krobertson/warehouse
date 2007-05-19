class RepositoriesController < ApplicationController
  def index
    @repositories = Repository.find(:all)
  end
  
  def show
    @repository = Repository.find(params[:id])
  end
  
  def update
    @repository = Repository.find(params[:id])
    if @repository.update_attributes(params[:repository])
      flash[:notice] = "Repository: #{@repository.name} saved successfully."
      redirect_to admin_path
    else
      flash[:error] = "Repository did not save."
      render :action => 'show'
    end
  end
  
  protected
    def admin_required
      admin? || access_denied
    end
end
