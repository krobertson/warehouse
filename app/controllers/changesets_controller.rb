class ChangesetsController < ApplicationController
  def index
    @changesets = repository.changesets.paginate(:page => params[:page], :order => 'revision desc')
  end
  
  def show
    @changeset = repository.changesets.find_by_revision(params[:id])
  end
end
