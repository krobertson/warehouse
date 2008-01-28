$LOAD_PATH << File.join(File.dirname(__FILE__), '..', '..', '..', 'vendor', 'grit', 'lib')
require 'grit'

module Silo
  module Adapters
    module Git
      module NodeMethods
        def dir?
          grit_object.is_a?(Grit::Tree)
        end

        def file?
          grit_object.is_a?(Grit::Blob)
        end
      
        def exists?
          !grit_object.nil?
        end

        def latest?
          (@latest ||= commit.committed_date >= latest_commit.committed_date || :false) != :false
        end

        def author
          if committer = commit && commit.committer
            committer.name
          else
            ''
          end
        end
        
        def message
          commit ? commit.message : ''
        end
        
        def changed_at
          commit ? commit.committed_date.utc : nil
        end

        def content(&block)
          return nil unless file?
          if block
            block.call(git_object.data)
          else
            grit_object.data
          end
        end

        def added_directories
        end
  
        def added_files
        end
  
        def updated_directories
        end
  
        def updated_files
        end
  
        def copied_directories
        end
  
        def copied_files
        end
  
        def deleted_directories
        end
  
        def deleted_files
        end

        def commit
          @commit ||= begin
            @revision ? @commit = @repository.find_commit(@revision) : revision
            @commit
          end
        end

        def revision
          @revision ||= begin
            @latest   = true
            @commit   = @repository.latest_commit_for(self)
            @latest_revision = @commit ?  @commit.id : nil
          end
        end
        
        def latest_commit
          @latest_commit ||= @repository.latest_commit_for(self)
        end
        
        def latest_revision
          @latest_revision ||= revision_for latest_commit
        end

        def previous_node
          @previous_node ||= begin
            parent = commit.parents.first
            parent ? @repository.node_at([@branch, @path] * "/", parent.id) : nil
          end
        end

        def branch
          @branch
        end

        def grit_object
          @grit_object ||= (path.size.zero? ? head : head / path) || :none
          @grit_object == :none ? nil : @grit_object
        end
        
        def head
          @head ||= @revision ? @repository.find_commit(@revision).tree : @repository.tree(branch)
        end

      protected
        def path=(value)
          pieces = value.to_s.split("/")
          while pieces.size > 0 && (@branch.nil? || @branch.size == 0)
            @branch = pieces.shift
          end
          @paths = pieces
          @path  = pieces * "/"
        end
        
        def revision_for(commit)
          @repository.revision_for(commit)
        end
      end

      def latest_revision
        backend && backend.commits.first.id
      end
      
      def commit_after(commit)
        backend && backend.commits(commit.id, 1, 1).first
      end

      def revision?(rev)
        rev =~ /^\w{40}$/ ? rev : nil
      end
      
      def blame_for(node)
        return nil unless node.file?
        blame = {:username_length => 0}
        num = 0
        Grit::Blob.blame(backend, node.revision, node.path).each do |(commit, lines)|
          lines.each do |line|
            num += 1
            username = commit.committer.name
            blame[num] = [commit.id, username]
            blame[:username_length] = [blame[:username_length], username.length].max
          end
        end
        blame
      end

      def child_node_names_for(node)
        return [] unless node.branch.nil? || node.dir?
        if node.branch.to_s.size.zero?
          backend.heads
        else
          node.grit_object.contents
        end.collect { |h| h.name }
      end

      def full_path_for(node)
        File.join(@options[:path], node.path)
      end
      
      def find_commit(id)
        backend.commit(id)
      end
      
      def latest_commit_for(node)
        backend.log(node.branch, node.path, :max_count => 1).first
      end
      
      def revision_for(commit)
        commit ? commit.id : nil
      end

      def unified_diff_for(old_rev, new_rev, diff_path)
        Grit::Commit.diff(backend, old_rev, new_rev).collect do |d| 
          "diff --git a/#{d.a_path} b/#{d.b_path}\nindex #{d.a_commit.id_abbrev}..#{d.b_commit.id_abbrev}\n#{d.diff}"
        end.join("\n")
      end

      def tree(*args)
        backend && backend.tree(*args)
      end
    
    protected
      def backend
        @backend ||= @options[:path].to_s.size.zero? ? nil : Grit::Repo.new(@options[:path].to_s)
      end
    end
  end
end