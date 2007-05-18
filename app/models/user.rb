class User < ActiveRecord::Base
  validates_presence_of :identity_url
  validates_uniqueness_of :identity_url
  before_save :set_admin_if_needed
  attr_accessible :name, :identity_url

  protected
    def set_admin_if_needed
      self.admin = true if User.count.zero?
      true
    end
end
