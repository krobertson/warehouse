module Warehouse
  module Plugins
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
        next unless File.directory?(dir)
        plugin = const_set(Base.class_name_of(name), Class.new(Base))
        discovered << plugin unless discovered.include?(plugin)
        index[plugin.plugin_name] = plugin
      end
    end

    self.discovered = []
    self.index      = {}
  end
end