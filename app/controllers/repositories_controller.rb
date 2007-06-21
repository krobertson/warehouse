class RepositoriesController < ApplicationController
  skip_before_filter :check_for_repository
  before_filter :admin_required
  before_filter :find_or_initialize_repository

  def index
    @repositories = admin? ? Repository.find(:all) : [current_repository]
    if current_repository
      @repositories.unshift current_repository
      @repositories.uniq!
    end
  end
  
  def create
    if @repository.save
      flash[:notice] = "Repository: #{@repository.name} created successfully."
      redirect_to admin_path
    else
      flash[:error] = "Repository did not save."
      render :action => 'show'
    end
  end
  
  def update
    if @repository.save
      flash[:notice] = "Repository: #{@repository.name} saved successfully."
      redirect_to admin_path
    else
      flash[:error] = "Repository did not save."
      render :action => 'show'
    end
  end
  
  def sync
    progress, error = @repository.sync_revisions(100)
    if error.blank?
      render :text => ((progress.split("\n").last.to_f / @repository.latest_revision.to_f) * 100).ceil.to_s
    else
      render :text => error, :status => 500
    end
  end
  
  protected
    def find_or_initialize_repository
      @repository = params[:id] ? Repository.find(params[:id]) : Repository.new
      @repository.attributes = params[:repository] unless params[:repository].blank?
    end

    def check_for_repository
      return true if repository_subdomain.blank? && admin?
      super
    end
end
