class RepositoriesController < ApplicationController
  before_filter :admin_required,            :only   => :create
  before_filter :repository_admin_required, :except => :create
  before_filter :find_or_initialize_repository

  def index
    @repositories = admin? ? Repository.find(:all) : current_user.administered_repositories
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
      logger.warn "Error syncing #{@repository.name.inspect} -- #{error}"
      render :text => error, :status => 500
    end
  end
  
  def destroy
    @repository.destroy
    respond_to do |format|
      format.js
    end
  end
  
  protected
    def find_or_initialize_repository
      @repository = params[:id] ? (admin? ? Repository : current_user.administered_repositories).find(params[:id]) : Repository.new
      @repository.attributes = params[:repository] unless params[:repository].blank?
    end

    def check_for_repository
      (repository_subdomain.blank? && admin?) || super
    end
    
    def repository_admin_required
      (repository_subdomain.blank? && admin?) || super
    end
end
