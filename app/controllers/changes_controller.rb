class ChangesController < ApplicationController
  def index
    redirect_to hosted_url(:changeset, params[:changeset_id])
  end
  
  def show
    @changeset = current_repository.changesets.find_by_revision(params[:changeset_id])
    @change    = @changeset.changes.find(params[:id])
    unless @change.accessible_by?(current_user)
      status_message :error, "You do not have access to this change."
      return
    end
    respond_to do |format|
      format.html
      format.diff { render :partial => 'change', :object => @change }
    end
  end
end
