class PhotoGalleryController < ApplicationController
  before_filter :repository_member_required

  def index
    @photos = current_repository.changes.find_recent_photos
  end
end