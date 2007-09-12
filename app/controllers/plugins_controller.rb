class PluginsController < ApplicationController
  skip_before_filter :check_for_repository
  before_filter :admin_required

  def index
    Warehouse::Plugins.load
    @plugin  = Plugin.new
    @plugins = Warehouse::Plugins.discovered
  end
  
  def update
    @plugin = Plugin.find(params[:id])
    params[:plugin] ||= {}
    @plugin.active  = params[:plugin].delete(:active)
    @plugin.options = params[:plugin].to_hash
    respond_to do |format|
      format.js
    end
  end
end
