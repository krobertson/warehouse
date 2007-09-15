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
    @plugin.options = params[:plugin]
    respond_to do |format|
      format.js
    end
  end
end
