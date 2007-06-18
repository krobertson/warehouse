module Warehouse
  @@forum_url = "http://forum.activereload.net/licenses/%s/installs"
  mattr_accessor :multiple_repositories, :domain, :forum_url

  def self.configure(&block)
    require 'dispatcher'
    Dispatcher.to_prepare do
      block.call(self)
    end
  end
end