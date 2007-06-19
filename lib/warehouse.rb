require 'digest/sha1'
module Warehouse
  @@forum_url = "http://forum.activereload.net/licenses/%s/installs"
  mattr_accessor :domain, :forum_url
end