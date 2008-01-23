module Silo
  module Adapters
    module Svn
      def latest_revision
        backend && backend.youngest_rev
      end

      def mime_type_for(node)
        base_mime_type_for node, 
          (node.exists? && !node.dir?) ? node.root.node_prop(node.path, ::Svn::Core::PROP_MIME_TYPE) : nil
      end
      
      def dir?(node)
        node.type_code == ::Svn::Core::NODE_DIR
      end
      
      def exists?(node)
        node.type_code != ::Svn::Core::NODE_NONE
      end
      
      def child_node_names_for(node)
        node.dir? ? node.root.dir_entries(node.path).keys : []
      end

      def blame_for(node)
        lines = {:username_length => 0}
        client.blame("file://#{node.full_path}") do |num, rev, username, changed_at, line|
          lines[num+1] = [rev, username]
          lines[:username_length] = [lines[:username_length], username.length].max
        end
        lines
      end
      
      def full_path_for(node)
        File.join(@options[:path], node.path)
      end
      
      def latest_revision_for(node)
        node.root.node_created_rev(node.path)
      end
      
      def author_for(node)
        node.exists? ? prop(::Svn::Core::PROP_REVISION_AUTHOR, node).to_s : ''
      end
      
      def message_for(node)
        node.exists? ? prop(::Svn::Core::PROP_REVISION_LOG, node).to_s : ''
      end
      
      def changed_at_for(node)
        node.exists? ? prop(::Svn::Core::PROP_REVISION_DATE, node).utc : nil
      end
      
      def content_for(node)
        node.root.file_contents(node.path) do |s|
          data = s.read
          GC.start
          data
        end      
      end
      
    protected
      def client
        @client ||= ::Svn::Client::Context.new
      end
      
      def backend
        @backend ||= @options[:path].to_s.size.zero? ? nil : ::Svn::Repos.open(@options[:path])
      end
      
      def prop(const, node)
        backend.fs.prop(const, node.revision)
      end
    end
  end
end

class Silo::Node
  def type_code
    @type_code ||= root.check_path(@path)
  end

  def root
    @root ||= @repository.send(:backend).fs.root(@revision || @repository.latest_revision)
  end
  
  def previous_root
    @previous_root ||= @repository.send(:backend).fs.root(revision - 1)
  end
end

require 'svn/core'
require 'svn/repos'
require 'svn/delta'
require 'svn/client'
require 'svn/wc'

# SVN Manual Garbage Collection
# http://retrospectiva.org/browse/trunk/lib/patches.rb?format=txt&rev=141
module Svn
  @@dirty_runs = 0
  def self.sweep_garbage!
    GC.start if (@@dirty_runs = (@@dirty_runs + 1) % 10).zero?
  end 

  module Fs
    class FileSystem
      def root_with_gc(rev = nil)
        Svn.sweep_garbage!
        root_without_gc(rev)
      end      
      alias_method :root_without_gc, :root
      alias_method :root, :root_with_gc
    end

    class Root
      def copied_from_with_gc(*args)
        Svn.sweep_garbage!
        copied_from_without_gc(*args)
      end
      alias_method :copied_from_without_gc, :copied_from
      alias_method :copied_from, :copied_from_with_gc

      def close_with_gc
        ret = close_without_gc
        Svn.sweep_garbage!
        ret
      end
      alias_method :close_without_gc, :close
      alias_method :close, :close_with_gc

      def file_contents_with_gc(*args, &block)
        Svn.sweep_garbage!
        file_contents_without_gc(*args, &block)
      end
      alias_method :file_contents_without_gc, :file_contents
      alias_method :file_contents, :file_contents_with_gc
    end
  end

  module Delta
    class ChangedEditor
      def add_file_with_gc(*args)
        Svn.sweep_garbage!
        add_file_without_gc(*args)
      end
      
      alias_method :add_file_without_gc, :add_file
      alias_method :add_file, :add_file_with_gc
    end
  end
end