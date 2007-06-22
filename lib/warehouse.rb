module Warehouse
  @@forum_url = "http://forum.activereload.net/licenses/%s/installs"
  mattr_accessor :domain, :forum_url, :permission_command, :password_command
end