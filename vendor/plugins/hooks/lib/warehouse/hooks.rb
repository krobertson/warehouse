module Warehouse
  module Hooks
    class << self
      attr_accessor :discovered
      attr_accessor :index

      def [](plugin_name)
        index[plugin_name]
      end
    end
  
    def self.discover(path)
      Dir[File.join(path, "*")].each do |dir|
        name = File.basename(dir)
        next unless File.directory?(dir) && !%w(lib test).include?(name)
        require File.join(dir, 'hook')
        hook = const_get(Base.class_name_of(name))
        discovered << hook
        index[hook.plugin_name] = hook
      end
    end
    
    def self.define(name, &block)
      const_set Base.class_name_of(name), MethodDefinitionProxy.proxy(Base, &block)
    end

    self.discovered = []
    self.index = {}
  end
end

class MethodDefinitionProxy
  attr_reader :klass

  def self.proxy(parent, &block)
    proxy = new(Class.new(parent))
    if block.arity == 1 # proxy is yielded
      block.call proxy
    else
      proxy.run &block # no block variable, assume they're defining #run
    end
    proxy.klass
  end

  def initialize(klass)
    @klass = klass
  end
  
  private
    def method_missing(name, *args, &block)
      if name == 'run'
        method_name = name
      else
        method_name = "retrieving_#{name}"
        klass.expiring_attr_reader name, method_name
      end
      klass.send :define_method, method_name, &block
    end
end