class ChangesController < ApplicationController
  def index
    redirect_to changesets_path(params[:changeset_id])
  end
  
  def show
    @changeset = repository.changesets.find_by_revision(params[:changeset_id])
    @change    = @changeset.changes.find_by_id(params[:id])
    respond_to do |format|
      format.html
      format.diff { render :partial => 'change', :object => @change }
    end
  end
end
