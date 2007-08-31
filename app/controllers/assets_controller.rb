class AssetsController < ApplicationController
  session :off
  caches_page :show

  def show
    if !params[:paths].blank? && plugin = Warehouse::Plugins.discovered.detect { |p| p.plugin_name == params[:plugin] }
      filename = File.join(plugin.plugin_path, 'public', params[:asset], *params[:paths])
      if File.exist?(filename)
        content_type = content_type_for params[:paths].last
        if content_type =~ /^text/
          render :text => IO.read(filename), :content_type => content_type
        else
          send_file filename, :type => content_type, :disposition => 'inline', :stream => false
        end
      else
        head :not_found
      end
    else
      head :not_found
    end
  end

  protected
    def content_type_for(path)
      case File.extname(path)
        when '.js'           then 'text/javascript'
        when '.css'          then 'text/css'
        when '.png'          then 'image/png'
        when '.jpg', '.jpeg' then 'image/jpeg'
        when '.gif'          then 'image/gif'
        when '.swf'          then 'application/x-shockwave-flash'
        when '.ico'          then 'image/x-icon'
      end
    end
end