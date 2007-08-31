module Warehouse
  module Hooks
    @@hook_path = RAILS_ENV == 'test' ? 'test/hooks' : 'vendor/plugins/hooks'
    mattr_reader :hook_path

    class << self
      attr_accessor :discovered
      attr_accessor :index

      def [](plugin_name)
        index[plugin_name]
      end
    end

    def self.for(repository)
      hooks = repository.hooks.index_by { |h| h.name }
      discover.collect { |h| hooks[h.plugin_name] || h }
    end

    def self.discover(path = nil)
      path ||= Warehouse::Hooks.hook_path
      Dir[File.join(path, "*")].each do |dir|
        name = File.basename(dir)
        next unless File.directory?(dir)
        hook_name = Base.class_name_of(name)
        require File.join(dir, 'hook') unless const_defined?(hook_name)
        next if index.key?(name)
        hook = const_get(hook_name)
        discovered             << hook
        index[hook.plugin_name] = hook
      end
      discovered
    end
    
    def self.define(name, &block)
      hook_class = Class.new(Base)
      hook_class.option :prefix, "(Optional) Regular expression matching on the updated files' paths to determine if the current commit should use this hook. "
      Proxy.process!(hook_class, &block)
      const_set Base.class_name_of(name), hook_class
    end

    self.discovered = []
    self.index      = {}

    class Proxy
      attr_reader :klass
    
      def self.process!(klass, &block)
        new(klass).instance_eval &block
      end
    
      def initialize(klass)
        @klass = klass
      end
      
      private
        def method_missing(name, *args, &block)
          if klass.respond_to?(name)
            klass.send(name, *args)
          else
            if %w(run init).include?(name.to_s)
              method_name = name
            else
              method_name = "retrieving_#{name}"
              klass.expiring_attr_reader name, method_name
            end
            klass.send :define_method, method_name, &block
          end
        end
    end
  end
end