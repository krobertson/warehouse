class ChangesetsController < ApplicationController
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
end
