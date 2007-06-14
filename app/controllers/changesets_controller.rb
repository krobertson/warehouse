class ChangesetsController < ApplicationController
  helper_method :previous_changeset, :next_changeset
  expiring_attr_reader :changeset_paths, :find_changeset_paths

  def index
    @changesets = case changeset_paths
      when :all then current_repository.changesets.paginate(:page => params[:page], :order => 'changesets.revision desc')
      when []   then []
      else current_repository.changesets.paginate_by_paths(changeset_paths, :page => params[:page], :order => 'changesets.revision desc')
    end
    respond_to do |format|
      format.html do
        @users = User.find_all_by_logins(current_repository, @changesets.collect(&:author).uniq).index_by(&:login)
      end
      format.atom do
        render :layout => false, :action => 'index'
      end
    end
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
      current_repository.changesets.find_by_paths(changeset_paths, :conditions => ['revision < ?', params[:id]], :order => 'revision desc')
    end
    
    def find_next_changeset
      current_repository.changesets.find_by_paths(changeset_paths, :conditions => ['revision > ?', params[:id]], :order => 'revision desc')
    end
    
    def find_changeset_paths
      if current_repository.public? || (logged_in? && current_user.admin?)
        :all
      else
        (logged_in? && current_user.permissions.paths_for(current_repository)) || []
      end
    end
end
