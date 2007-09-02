module Warehouse
  module Plugins
    class PhotoGallery < Warehouse::Plugins::Base
      resources :photos, :controller => 'photo_gallery'

      def self.load
        super
        require 'change_methods'
        ApplicationController.prepend_view_path view_path unless ApplicationController.view_paths.include?(view_path)
      end
    end
  end
end