module Warehouse
  module Plugins
    class Base < PluginBase
      cattr_accessor :custom_routes, :view_paths, :tabs
      class << self
        def plugin_path
          @plugin_path ||= File.join(RAILS_ROOT, 'vendor', 'warehouse', 'plugins', plugin_name)
        end

        def view_path
          @view_path ||= File.expand_path(File.join(plugin_path, 'views'))
        end

        # Installs the plugin's tables using the schema file in lib/#{plugin_name}/schema.rb
        #
        #   script/runner -e production 'FooPlugin.install'
        #   => installs the FooPlugin plugin.
        #
        def install
          self::Schema.install
        end
      
        # Uninstalls the plugin's tables using the schema file in lib/#{plugin_name}/schema.rb
        def uninstall
          self::Schema.uninstall
        end
      
        # Adds a custom route to Mephisto from a plugin.  These routes are created in the order they are added.  
        # They will be the last routes before the Mephisto Dispatcher catch-all route.
        def route(*args)
          custom_routes << args
        end
      
        def resources(resource, options = {})
          route :resources, resource, options
          controller resource.to_s.humanize, resource
        end
      
        def resource(resource, options = {})
          route :resource, resource, options
          controller resource.to_s.humanize, resource
        end
  
        # Keeps track of custom adminstration tabs.  Each item is an array of arguments to be passed to link_to.
        #
        #   class Foo < Beast::Plugin
        #     tab 'Foo', :controller => 'foo'
        #   end
        def tab(*args)
          tabs << args
        end

        # Sets up a custom controller.  Beast::Plugin.public_controller is used for the basic setup.  This also automatically
        # adds a tab for you, and symlinks Mephisto's core app/views/layouts path.  Like Beast::Plugin.public_controller, this should be
        # called from your plugin's init.rb file.
        #
        #   class Foo < Beast::Plugin
        #     controller 'Foo', 'foo'
        #   end
        #
        #   class FooController < ApplicationController
        #     prepend_view_path Beast::Plugin.view_paths[:foo]
        #     ...
        #   end
        #
        # Your views will then be stored in #{YOUR_PLUGIN}/views/admin/foo/*.rhtml.
        def controller(title, name = nil, options = {})
          returning (name || title.underscore).to_sym do |controller_name|
            view_paths[controller_name] = File.join(plugin_path, 'views').to_s
            tab title, {:controller => controller_name.to_s}.update(options)
          end
        end

        protected
          def css_files
            @css_files ||= Dir[File.join(plugin_path, 'public', 'stylesheets', '*.css')]
          end
          
          def js_files
            @js_files ||= Dir[File.join(plugin_path, 'public', 'javascripts', '*.js')]
          end
      end
      
      def initialize(options = {}, &block)
        super(options, &block)
        install_routes!
      end

      def head_extras
        @head_extras ||= 
          (css_files.collect { |f| %(<link href="#{sanitize_path f}" rel="stylesheet" type="text/css" />) } * "\n") + 
          (js_files.collect  { |f| %(<script src="#{sanitize_path f}" type="text/javascript"></script>)   } * "\n")
      end

      %w(plugin_path view_path).each do |method_name|
        define_method method_name do 
          self.class.send method_name
        end
      end

      protected
        def install_routes!
          return unless Object.const_defined?(:ActionController)
          mapper = ActionController::Routing::RouteSet::Mapper.new(ActionController::Routing::Routes)
          self.class.custom_routes.each do |args|
            mapper.send *args
          end
        end
      
        def sanitize_path(path)
          sanitized = path[plugin_path.size + 7..-1]
          sanitized.gsub! /^\/([^\/]+)\// do |path|
            path << plugin_name << '/'
          end
        end

      self.custom_routes = []
      self.view_paths    = {}
      self.tabs          = []
    end
  end
end