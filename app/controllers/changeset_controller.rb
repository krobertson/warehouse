class ChangesetController < ApplicationController
  def index
    @changesets = Changeset.find(:all)
  end
  
  def show
    @changeset = Changeset.find_by_revision(params[:rev])
  end
  
end
