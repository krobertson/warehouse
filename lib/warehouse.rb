module Warehouse
  extend self
  mattr_accessor :multiple_repositories
  
  def configure(&block)
    require 'dispatcher'
    Dispatcher.to_prepare do
      block.call(self)
    end
  end
end