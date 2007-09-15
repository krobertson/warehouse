module Warehouse
  module Plugins
    class PhotoGallery < Warehouse::Plugins::Base
      author 'Active Reload'
      version '1.0'
      homepage 'http://activereload.net'
      notes 'Collects all the images from your repository and displays them in a gallery'

      resources :photos, :controller => 'photo_gallery', :icon => 'gallery-small.png'
      
      def self.load
        super
        require 'change_methods'
      end
    end
  end
end