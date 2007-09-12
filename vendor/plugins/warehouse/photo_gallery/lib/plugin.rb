module Warehouse
  module Plugins
    class PhotoGallery < Warehouse::Plugins::Base
      resources :photos, :controller => 'photo_gallery'
      
      author 'Active Reload'
      version '1.0'
      homepage 'http://activereload.net'
      notes 'Collects all the images from your repository and displays them in a gallery'
      
      def self.load
        super
        require 'change_methods'
        ApplicationController.prepend_view_path view_path unless ApplicationController.view_paths.include?(view_path)
      end
    end
  end
end