module Warehouse
  module Hooks
    class Base < PluginBase
      attr_reader :instance
      attr_reader :commit

      def initialize(instance, commit = nil, &block)
        @instance = instance
        @commit   = commit
        super(options, &block)
      end

      def self.properties
        @properties ||= new
      end
      
      def active
        @instance && @instance.active
      end
      
      def active?
        @instance && @instance.active?
      end
      
      def active=(value)
        @instance && @instance.active = value
      end
      
      def label
        @instance && @instance.label
      end
      
      def label=(value)
        @instance && @instance.label = value
      end
      
      def options
        (@instance && @instance.options) || {}
      end

      # checks if the commit matches the optional prefix
      def valid?
        return false unless active?
        return true if options[:prefix].to_s.empty?
        options[:prefix] = Regexp.new(options[:prefix].to_s.gsub(/(^\/)|(\/$)/, '')) unless options[:prefix].is_a?(Regexp)
        @commit.dirs_changed.split(/\n/).any? { |path| path =~ options[:prefix] }
      end
      
      def run!
        init if respond_to?(:init) # plugin-specific startup stuff
        run
      end
    end
  end
end