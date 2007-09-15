module Warehouse
  module Plugins
    class << self
      attr_accessor :discovered
      attr_accessor :index
      attr_accessor :loaded

      def [](plugin_name)
        index[plugin_name.to_s]
      end
    end

    def self.discover(path = nil)
      path  ||= Plugin.plugin_class_path
      plugins = find_in(path)
      records = Plugin.find_from(plugins)
      discovered.clear
      index.clear
      plugins.each do |p|
        record = records.detect { |r| r.name == p } || Plugin.create_empty_for(p)
        next if index.key?(p)
        discovered << record
        index[p]    = record
      end
      discovered
    end
    
    def self.load(path = nil)
      discover(path).each do |plugin|
        if !loaded.include?(plugin) && plugin.active?
          plugin.plugin_class.load
          loaded << plugin
        end
      end
      loaded.delete_if { |plugin| !plugin.active? }
      loaded
    end

    def self.find_in(path)
      Dir[File.join(path, '*')].select { |d| File.directory?(d) && File.file?(File.join(d, 'lib', 'plugin.rb')) }.collect! { |d| File.basename(d) }
    end
    
    def self.each_tab
      loaded.each do |plugin|
        plugin.tabs.each do |tab|
          yield tab
        end
      end
    end
    
    def self.tabs?
      loaded.delete_if { |plugin| !plugin.active? }
      loaded.size > 0
    end

    self.discovered = []
    self.index      = {}
    self.loaded     = []
  end
end