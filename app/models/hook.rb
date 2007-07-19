class Hook < ActiveRecord::Base
  belongs_to :repository
  serialize :options, Hash
  
  validates_presence_of :repository_id, :name
  
  def properties
    Warehouse::Hooks[name].new(nil, options || {})
  end
end
