class BookmarkSweeper < ActionController::Caching::Sweeper
  observe Bookmark
  
  def after_save(bookmark)
    expire_fragment CacheKey.bookmarks_for(bookmark.repository_id)
  end
  
  alias after_destroy after_save
end