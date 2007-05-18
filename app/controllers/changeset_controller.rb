class ChangesetController < ApplicationController
  def index
    @changesets = repository.changesets
  end
  
  def show
    @changeset = repository.changesets.find_by_revision(params[:rev])
  end
  
end
