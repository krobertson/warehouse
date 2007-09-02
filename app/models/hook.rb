class Hook < ActiveRecord::Base
  belongs_to :repository
  serialize :options, Hash
  
  validates_presence_of :repository_id, :name
  validate :hook_options_are_valid?
  
  before_create :set_default_active_state
  
  def properties
    @properties ||= Warehouse::Hooks[name].new(nil, options || {})
  end
  
  def options
    read_attribute(:options) || write_attribute(:options, {})
  end
  
  protected
    def set_default_active_state
      self.active = true
    end

    def hook_options_are_valid?
      errors.add_to_base("Hook options are invalid") unless properties.valid_options?(options)
    end
end
