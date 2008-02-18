module Silo
  module Adapters
    module Svn
      module NodeMethods
        def dir?
          type_code == ::Svn::Core::NODE_DIR
        end
        
        def file?
          type_code == ::Svn::Core::NODE_FILE
        end
        
        def exists?
          type_code != ::Svn::Core::NODE_NONE
        end
        
        def child_node_names
          dir? ? root.dir_entries(path).keys : []
        end
        
        def blame
          return nil unless file?
          @blame ||= begin
            lines = {:username_length => 0}
            client.blame("file://#{full_path}") do |num, rev, username, changed_at, line|
              lines[num+1] = [rev, username]
              lines[:username_length] = [lines[:username_length], username.length].max
            end
            lines
          end
        end
        
        def latest_revision
          @repository.node_at(path).revision
        end
        
        def content(&block)
          total = []
          root.file_contents(path) do |s|
            data = s.read
            block ? block.call(data) : total << data
          end
          GC.start
          block ? nil : total.join
        end

        def type_code
          @type_code ||= root.check_path(@path)
        end

        def root
          @root ||= @repository.send(:backend).fs.root(@revision || @repository.latest_revision)
        end
  
        def previous_root
          @previous_root ||= @repository.send(:backend).fs.root(revision - 1)
        end
  
        def added_files
          @added_files ||= changed_editor.added_dirs + changed_editor.added_files
        end
  
        def updated_files
          @updated_files ||= changed_editor.updated_dirs + changed_editor.updated_files
        end
  
        def copied_files
          @copied_files ||= changed_editor.copied_dirs + changed_editor.copied_files
        end

        def deleted_files
          @deleted_files = changed_editor.deleted_dirs + changed_editor.deleted_files
        end

      protected
        def client
          @client ||= ::Svn::Client::Context.new
        end

        def revision=(value)
          @revision = value.nil? ? nil : value.to_i
        end

        def changed_editor
          unless @changed_editor
            @changed_editor = ::Svn::Delta::ChangedEditor.new(root, previous_root)
            previous_root.dir_delta('', '', root, '', @changed_editor)
          end
          @changed_editor
        end
      end

      def latest_revision
        backend && backend.youngest_rev
      end
      
      def revision?(rev)
        case rev
          when /^\d+$/ then rev.to_i
          when Fixnum  then rev
          else nil
        end
      end

      def full_path_for(node)
        File.join(@options[:path], node.path)
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

      def unified_diff_for(old_rev, new_rev, diff_path)
        new_rev = new_rev.revision if new_rev.respond_to?(:revision)
        old_rev = old_rev.revision if old_rev.respond_to?(:revision)
        old_rev = new_rev - 1 if old_rev.nil?
        old_root  = backend.fs.root old_rev
        new_root  = backend.fs.root new_rev
        
        differ = ::Svn::Fs::FileDiff.new(old_root, diff_path, new_root, diff_path)

        diff = 
          if differ.binary?
            ''
          else
            old = "#{diff_path} (revision #{old_rev})"
            cur = "#{diff_path} (revision #{new_rev})"
            differ.unified(old, cur)
          end
        [old_rev, new_rev, diff]
      end
      
    protected
      def backend
        @backend ||= @options[:path].to_s.size.zero? ? nil : ::Svn::Repos.open(@options[:path])
      end
      
      def prop(const, node)
        backend.fs.prop(const, node.revision)
      end
    end
  end
end

%w(core error repos delta client wc).each { |lib| require "svn/#{lib}" }

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