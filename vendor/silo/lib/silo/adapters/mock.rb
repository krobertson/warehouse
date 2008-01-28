require 'yaml'

module Silo
  module Adapters
    module Mock
      module NodeMethods
      end

      def latest_revision
        config[:latest_revision]
      end
      
      def dir?(node)
        File.directory?(node.full_path)
      end
      
      def file?(node)
        File.file?(node.full_path)
      end
      
      def exists?(node)
        File.exist?(node.full_path)
      end
      
      def child_node_names_for(node)
        Dir.chdir node.full_path do
          Dir["*"]
        end
      end

      def blame_for(node)
        info_for(node)[:blame]
      end
      
      def full_path_for(node)
        File.join(@options[:path], node.path)
      end
      
      def latest_revision_for(node)
        info_for(node)[:revision].to_i
      end
      
      [:author, :message, :changed_at].each do |attr|
        define_method "#{attr}_for" do |node|
          info_for(node)[attr]
        end
      end
      
      def content_for(node)
        IO.read(node.full_path) if file?(node)
      end
      
    protected
      def info_for(node)
        config[:files][node.path] || {}
      end
      
      def config
        @config ||= YAML.load_file(File.join(@options[:path], 'config.yml'))
      end
    end
  end
end