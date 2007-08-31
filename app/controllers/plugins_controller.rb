class PluginsController < ApplicationController
  before_filter :admin_required

  def index
    @plugin  = Plugin.new
    @plugins = Plugin.find_discovered
  end
  
  def create
    @plugin = Plugin.create(params[:plugin])
    respond_to do |format|
      format.js
    end
  end
  
  def update
    @plugin = Plugin.find(params[:id])
    @plugin.options = params[:plugin].to_hash
    respond_to do |format|
      format.js
    end
  end
  
  def destroy
    @plugin = Plugin.find(params[:id])
    @plugin.destroy
    respond_to do |format|
      format.js
    end
  end
end
