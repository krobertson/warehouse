module Warehouse
  module Plugins
    class PhotoGallery < Warehouse::Plugins::Base
      def self.load
        super
        require 'change_methods'
        ApplicationController.prepend_view_path view_path unless ApplicationController.view_paths.include?(view_path)
      end
      
      resources :photos, :controller => 'photo_gallery'
    end
  end
end