Module.class_eval do
  # A hash that maps Class names to an array of Modules to mix in when the class is instantiated.
  @@class_mixins = {}
  mattr_reader :class_mixins

  # Specifies that this module should be included into the given classes when they are instantiated.
  #
  #   module FooMethods
  #     include_into "Foo", "Bar"
  #   end
  def include_into(*klasses)
    klasses.flatten!
    klasses.each do |klass|
      (@@class_mixins[klass] ||= []) << self
      @@class_mixins[klass].uniq!
    end
  end

  # add any class mixins that have been registered for this class
  def auto_include!
    mixins = @@class_mixins[name]
    send(:include, *mixins) if mixins
  end
end

Class.class_eval do
  # Instantiates a class and adds in any class_mixins that have been registered for it.
  def inherited_with_mixins(klass)
    returning inherited_without_mixins(klass) do |value|
      klass.auto_include!
    end
  end
  
  alias_method_chain :inherited, :mixins
end

REXML::Document.class_eval { def doctype() nil end }
ActionContentFilter.preserved_instance_variables = %w(@title @onready @fullscreen @current_sheets @content_for_scripts @content_for_onready @content_for_javascript @content_for_sidebar)

require 'open3'
require 'application'
require 'warehouse'
require 'warehouse/plugins'
require 'warehouse/hooks'
require 'plugin'
require 'hook'

begin
  require 'rubygems' unless Object.const_defined?(:Gem)
  require 'uv'
rescue LoadError
  puts "No Ultraviolet gem found, defaulting to javascript syntax highlighting.  Do not be afraid."
end

begin
  Warehouse::Hooks.discover
rescue ActiveRecord::StatementInvalid
  puts "Error loading hooks: #{$!}"
  puts "Make sure the database was created successfully and migrated."
end

begin
  Warehouse::Plugins.load
rescue ActiveRecord::StatementInvalid
  puts "Error loading plugins: #{$!}"
  puts "Make sure the database was created successfully and migrated."
end

if RAILS_ENV == 'development'
  ENV["RAILS_ASSET_ID"] = ''
end

