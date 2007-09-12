class PhotoGalleryController < Warehouse::PluginController
  before_filter :repository_member_required
  plugin :photo_gallery

  def index
    @photos = current_repository.changes.find_recent_photos(:page => params[:page])
  end
end