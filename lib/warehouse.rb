module Warehouse
  mattr_accessor :multiple_repositories
  mattr_accessor :domain
  
  def self.configure(&block)
    require 'dispatcher'
    Dispatcher.to_prepare do
      block.call(self)
    end
  end
end