class ChangesetsController < ApplicationController
  helper_method :previous_changeset, :next_changeset

  def index
    @changesets = current_repository.changesets.paginate(:page => params[:page], :order => 'revision desc')
  end
  
  def show
    @changeset = current_repository.changesets.find_by_revision(params[:id])
    respond_to do |format|
      format.html
      format.diff { render :layout => false }
    end
  end

  protected
    def previous_changeset
      @previous_changeset ||= current_repository.changesets.find(:first, :conditions => ['revision < ?', params[:id]], :order => 'revision desc')
    end
    
    def next_changeset
      @next_changeset ||= current_repository.changesets.find(:first, :conditions => ['revision > ?', params[:id]], :order => 'revision')
    end
end
