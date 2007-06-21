class BookmarksController < ApplicationController
  before_filter :repository_admin_required
  
  def create
    @bookmark = current_repository.bookmarks.create(params[:bookmark])
    respond_to do |format|
      format.js
    end
  end
end
