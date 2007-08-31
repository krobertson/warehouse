module Warehouse
  module Hooks
    class Base < PluginBase
      def initialize(commit, options = {}, &block)
        @commit  = commit
        super(options, &block)
      end
      
      # checks if the commit matches the optional prefix
      def valid?
        return true if @options[:prefix].to_s.empty?
        @options[:prefix] = Regexp.new(@options[:prefix].to_s.gsub(/(^\/)|(\/$)/, '')) unless @options[:prefix].is_a?(Regexp)
        @commit.dirs_changed.split(/\n/).any? { |path| path =~ @options[:prefix] }
      end
      
      def run!
        init if respond_to?(:init) # plugin-specific startup stuff
        run
      end
    end
  end
end