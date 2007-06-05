class BookmarksController < ApplicationController
  before_filter :repository_admin_required
  
  def create
    @bookmark = current_repository.bookmarks.create(params[:bookmark])
    render :update do |page|
      page['bookmarks'].show
      page.insert_html :bottom, 'bookmark-list', :partial => 'bookmark'
      page.bookmark_sheet.hide
    end
  end
end
