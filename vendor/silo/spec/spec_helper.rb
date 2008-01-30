require 'rubygems'
require 'spec'
require 'fileutils'

begin
  require 'ruby-debug'
  Debugger.start
rescue LoadError
  # no debugging for you!
end

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require "silo"

$adapter_options = {
  :mock => {:path => File.join(File.dirname(__FILE__), 'mock_repo')},
  :svn  => {:path => File.expand_path(File.join(File.dirname(__FILE__), 'svn_repo'))},
  :git  => {:path => File.expand_path(File.join(File.dirname(__FILE__), 'git_repo'))}
}

def load_adapter!
  $adapter_type = (ENV['ADAPTER'] || 'mock').to_sym
  require "silo/adapters/#{$adapter_type}"
  $adapter_class = Silo::Adapters.const_get($adapter_type.to_s.capitalize)
end