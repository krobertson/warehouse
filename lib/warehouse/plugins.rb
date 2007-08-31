module Warehouse
  module Plugins
    class << self
      attr_accessor :discovered
      attr_accessor :index
      attr_accessor :loaded

      def [](plugin_name)
        index[plugin_name]
      end
    end

    def self.discover(path = nil)
      path  ||= Plugin.plugin_path
      plugins = find_in(path)
      records = Plugin.find_from(plugins)
      plugins.each do |p|
        next if index.key?(p)
        record = records.detect { |r| r.name == p } || Plugin.create_empty_for(p)
        discovered << record
        index[p]    = record
      end
      discovered
    end
    
    def self.load(path = nil)
      discover(path).each do |plugin|
        if !loaded.include?(plugin) && plugin.plugin_class
          plugin.plugin_class.load
          loaded << plugin
        end
      end
      loaded
    end

    def self.find_in(path)
      Dir[File.join(path, '*')].select { |d| File.directory?(d) && File.file?(File.join(d, 'lib', 'plugin.rb')) }.collect! { |d| File.basename(d) }
    end

    self.discovered = []
    self.index      = {}
    self.loaded     = []
  end
end