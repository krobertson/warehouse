class Plugin < ActiveRecord::Base
  serialize :options, Hash
  
  validates_presence_of :name
  validate :plugin_options_are_valid?
  
  def self.find_discovered
    
  end
  
  def properties
    @properties ||= Warehouse::Plugins[name].new(options || {})
  end
  
  protected
    def plugin_options_are_valid?
      errors.add_to_base("Hook options are invalid") unless properties.valid_options?(options)
    end
end
