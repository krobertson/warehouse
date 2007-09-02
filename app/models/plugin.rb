class Plugin < ActiveRecord::Base
  @@plugin_path = File.join(RAILS_ROOT, RAILS_ENV == 'test' ? 'test/plugins' : 'vendor/plugins/warehouse')
  cattr_reader :plugin_path

  serialize :options, Hash
  
  before_validation_on_create :convert_name
  before_create :set_default_active_state
  validates_presence_of   :name
  validates_uniqueness_of :name
  validate :plugin_options_are_valid?

  def self.create_empty_for(name)
    create! :name => name, :options => {}, :active => false
  end
  
  def self.find_from(plugins)
    find(:all, :conditions => ['name IN (?)', plugins])
  end
  
  def plugin_class
    require File.join(plugin_path, name, 'lib', 'plugin') unless Warehouse::Plugins.const_defined?(plugin_class_name)
    @plugin_class ||= Warehouse::Plugins.const_get(plugin_class_name)
  end
  
  def plugin_class_name
    @plugin_class_name ||= Warehouse::Plugins::Base.class_name_of(name)
  end

  def properties
    @properties ||= plugin_class.new(options || {})
  end
  
  protected
    def set_default_active_state
      self.active = false ; true
    end

    def convert_name
      self.name = name.to_s.demodulize.underscore if name
    end

    def plugin_options_are_valid?
      return true unless active?
      if plugin_class.nil?
        errors.add_to_base "Plugin class is invalid" and return
      end
      errors.add_to_base("Plugin options are invalid") unless properties.valid_options?(options)
    end
end
