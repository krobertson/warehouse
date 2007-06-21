class ChangesetsController < ApplicationController
  helper_method :previous_changeset, :next_changeset
  expiring_attr_reader :changeset_paths, :find_changeset_paths

  def index
    if repository_subdomain.blank?
      if logged_in? 
        return global_index
      else
        return redirect_to(public_changesets_path)
      end
    end
    @changesets = case changeset_paths
      when :all then current_repository.changesets.paginate(:page => params[:page], :order => 'changesets.revision desc')
      when []   then []
      else current_repository.changesets.paginate_by_paths(changeset_paths, :page => params[:page], :order => 'changesets.revision desc')
    end
    respond_for_changesets
  end

  def public
    @repositories = Repository.find_all_by_public(true)
    @changesets   = Changeset.paginate(:conditions => ['repository_id in (?)', @repositories.collect(&:id)], :page => params[:page], :order => 'changesets.revision desc')
    respond_for_changesets
  end
  
  def global_index
    @repositories = current_user.repositories
    @changesets   = Changeset.paginate_by_paths(current_user.repositories.paths, :page => params[:page], :order => 'changesets.revision desc')
    respond_for_changesets
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
      current_repository.changesets.find_by_paths(changeset_paths, :conditions => ['revision > ?', params[:id]], :order => 'revision')
    end
    
    def find_changeset_paths
      if current_repository.public? || (logged_in? && current_user.admin?)
        :all
      else
        (logged_in? && current_user.permissions.paths_for(current_repository)) || []
      end
    end

    def respond_for_changesets
      respond_to do |format|
        format.html do
          @users = 
            if @repositories
              changesets_by_repo = @changesets.inject({}) do |memo, changeset|
                (memo[changeset.repository_id] ||= []) << changeset.author
                memo
              end
              changesets_by_repo.values.each &:uniq!
              
              User.find_all_by_repositories(changesets_by_repo)
            else
              {current_repository.id => User.find_all_by_logins(current_repository, @changesets.collect(&:author).uniq).index_by(&:login)}
            end
          render :action => 'index'
        end
        format.atom do
          render :layout => false, :action => 'index'
        end
      end
    end

    @@global_actions = %w(index public)
    def check_for_repository
      return true if repository_subdomain.blank? && @@global_actions.include?(action_name)
      super
    end
end
