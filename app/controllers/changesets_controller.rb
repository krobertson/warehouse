class ChangesetsController < ApplicationController
  helper_method :previous_changeset, :next_changeset

  def index
    @changesets = current_repository.changesets.paginate_by_paths(changeset_paths, :page => params[:page], :order => 'changesets.revision desc')
  end
  
  def show
    @changeset = current_repository.changesets.find_by_paths(changeset_paths, :conditions => ['revision = ?', params[:id]])
    respond_to do |format|
      format.html
      format.diff { render :layout => false }
    end
  end

  protected
    %w(previous_changeset next_changeset changeset_paths).each { |m| expiring_attr_reader m, "find_#{m}" }
    
    def find_previous_changeset
      current_repository.changesets.find_by_paths(changeset_paths, :conditions => ['revision < ?', params[:id]])
    end
    
    def find_next_changeset
      current_repository.changesets.find_by_paths(changeset_paths, :conditions => ['revision > ?', params[:id]])
    end
    
    def find_changeset_paths
      logged_in? && current_user.permissions.paths_for(current_repository) || []
    end
end
