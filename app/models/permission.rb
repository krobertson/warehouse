class Permission < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user
  before_create { |r| r.active = true }
  before_save   { |r| r.path   = r.path.to_s.gsub(/^\/|\/$/, '') }
  attr_accessible :user_id, :full_access, :path
  validates_presence_of :repository_id, :user_id
end
