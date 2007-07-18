module Warehouse
  module Hooks
    class Base < PluginBase
      def initialize(commit, options = {})
        @commit  = commit
        @options = options
        init # plugin-specific startup stuff
      end
      
      def init() end
      
      # checks if the commit matches the optional prefix
      def valid?
        return true if @options[:prefix].to_s.empty?
        @commit.dirs_changed.split(/\n/).any? { |path| path =~ @options[:prefix] }
      end
    end
  end
end