module Warehouse
  module Hooks
    class Base < Extension
      attr_reader :commit
      attr_reader :repo

      # The instance reference lets this class act like a hook record in the database.
      attr_accessor :instance

      def initialize(commit = nil, options = {}, &block)
        @commit   = commit
        @repo     = commit ? commit.repo : nil
        super(options, &block)
      end

      def self.properties
        @properties ||= new(nil)
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

      # checks if the commit matches the optional prefix
      def valid?
        return false unless instance.nil? || active?
        return true if options[:prefix].to_s.empty?
        unless options[:prefix].is_a?(Regexp)
          options[:prefix] = options[:prefix].to_s
          options[:prefix].gsub!(/(^\/)|(\/$)/, '')
          if options[:prefix] =~ /^[\w_\/-]+$/
            options[:prefix] = "^" + options[:prefix]
          end
          options[:prefix] = Regexp.new(options[:prefix])
        end
        @commit.dirs_changed.split(/\n/).any? { |path| path =~ options[:prefix] }
      end
      
      def run!
        init if respond_to?(:init) # plugin-specific startup stuff
        run
      end
    end
  end
end