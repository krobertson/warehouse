class RepositoriesController < ApplicationController
  skip_before_filter :check_for_repository
  before_filter :admin_required

  def index
    @repository   = Repository.new
    @repositories = Warehouse.multiple_repositories ? Repository.find(:all) : [Repository.find(:first)]
  end

  def show
    @repository = Repository.find(params[:id])
  end
  
  def create
    @repository = Repository.new(params[:repository])
    if @repository.save
      flash[:notice] = "Repository: #{@repository.name} created successfully."
      redirect_to admin_path
    else
      flash[:error] = "Repository did not save."
      render :action => 'show'
    end
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
end
