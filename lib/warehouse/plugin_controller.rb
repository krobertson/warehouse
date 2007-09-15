class Warehouse::PluginController < ApplicationController
  before_filter :check_for_active_plugin
  
  def self.plugin(name = nil)
    @plugin = Warehouse::Plugins[name] if name
    prepend_view_path @plugin.view_path
    @plugin
  end
  
  protected
    def check_for_active_plugin
      if self.class.plugin.nil?
        access_denied_message "No plugin found for this plugin controller."
      elsif !self.class.plugin.reload.active?
        access_denied_message "The #{self.class.plugin.name} plugin is inactive."
      end
    end
end