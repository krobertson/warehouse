class Permission < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user
  before_create { |r| r.active = true }
  validates_presence_of :repository_id
  attr_accessible :login, :admin, :path, :full_access

  def login
    l = read_attribute :login
    l.blank? ? '*' : l
  end
  
  def formatted_path
    "/#{path}"
  end

  def self.grant(repository, options = {}, &block)
    if paths = options.delete(:paths)
      permissions = paths.collect { |p| grant(repository, options.merge(p), &block) }
      return permissions.reject(&:new_record?).first
    end
    m = repository.all_permissions.build
    m.active     = true
    m.attributes = options
    block.call(m) if block
    m.save
    m
  end
end
