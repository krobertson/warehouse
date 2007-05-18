class ChangesetsController < ApplicationController
  def index
    @changesets = repository.changesets.paginate(:page => params[:page], :order => 'revision desc')
  end
  
  def show
    @changeset = repository.changesets.find_by_revision(params[:id])
    respond_to do |format|
      format.html
      format.diff { render :layout => false }
    end
  end
end
