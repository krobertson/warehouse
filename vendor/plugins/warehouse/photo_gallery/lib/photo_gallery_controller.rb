class PhotoGalleryController < Warehouse::PluginController
  plugin :photo_gallery
  before_filter :repository_member_required

  def index
    @photos = current_repository.changes.find_recent_photos(:page => params[:page])
  end
end