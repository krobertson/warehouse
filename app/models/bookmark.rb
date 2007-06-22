class Bookmark < ActiveRecord::Base
  validates_uniqueness_of :path, :scope => :repository_id
  validates_presence_of :label, :path
  attr_accessible :label, :path, :description
  
  belongs_to :repository
  
  def path=(value)
    write_attribute :path, value.to_s.gsub(/^\/|\/$/, '')
  end
  
  def paths
    path.to_s.split '/'
  end
end
