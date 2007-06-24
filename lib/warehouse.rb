module Warehouse
  class << self
    attr_accessor :domain, :forum_url, :permission_command, :password_command
  end
  self.forum_url = "http://forum.activereload.net/licenses/%s/installs"
end