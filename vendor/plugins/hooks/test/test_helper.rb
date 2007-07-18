rails_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..'))
hooks_root = File.join(rails_root, 'vendor', 'plugins', 'hooks')
require File.join(rails_root, 'lib', 'warehouse', 'plugin_base')
require File.join(hooks_root, 'lib', 'warehouse', 'hooks')
require File.join(hooks_root, 'lib', 'warehouse', 'hooks', 'base')
require File.join(hooks_root, 'lib', 'warehouse', 'hooks', 'commit')

Warehouse::Hooks.discover hooks_root

require 'rubygems'
require 'test/unit'
require 'mocha'
require 'test/spec'
require 'ruby-debug'

Debugger.start