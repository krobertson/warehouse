class Repository < ActiveRecord::Base
  has_permalink :name
  validates_presence_of :name, :path, :permalink
  attr_accessible :name, :path
  
  def path=(value)
    write_attribute(:path, value ? value.to_s.chomp('/') : nil)
  end
end
