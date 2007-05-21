class Membership < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user
  before_create { |r| r.active = true }
  validates_presence_of :repository_id, :user_id
  attr_accessible :login, :admin
end
