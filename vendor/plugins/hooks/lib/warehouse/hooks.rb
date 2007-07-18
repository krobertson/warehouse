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
      klass = Class.new(Base)
      klass.send(:define_method, :run, &block)
      const_set Base.class_name_of(name), klass
    end

    self.discovered = []
    self.index = {}
  end
end