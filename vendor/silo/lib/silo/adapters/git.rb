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
    
        def unified_diff_with(other_rev = nil)
          args = (other_rev ? [revision, other_rev] : [other_rev, revision]) << @only_path
          @repository.unified_diff_for(*args)
        end

        def added_files
          @added_files ||= collect_diffs { |d| d.new_file }
        end
  
        def updated_files
          @updated_files ||= collect_diffs { |d| !d.new_file && !d.deleted_file && d.a_path == d.b_path }
        end
  
        def copied_files
          @copied_files ||= collect_diffs { |d| !d.new_file && !d.deleted_file && d.a_path != d.b_path }
        end
  
        def deleted_files
          @deleted_files ||= collect_diffs { |d| d.deleted_file }
        end
        
        def diffs
          @repository.cached_diffs[commit] ||= commit.diffs
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
            parent ? @repository.node_at(@path, parent.id) : nil
          end
        end

        def branch
          @branch
        end
        
        def only_path
          @only_path
        end

        def grit_object
          @grit_object ||= begin
            only_paths = paths.dup ; only_paths.shift
            only_paths.inject(head) { |tree, path| tree ? (tree / path) : tree } || :none
          end
          @grit_object == :none ? nil : @grit_object
        end
        
        def head
          @head ||= @revision ? @repository.find_commit(@revision).tree : @repository.tree(@branch)
        end

      protected
        def path=(value)
          value.gsub! /(^\/)|(\/$)/, ''
          pieces = value.to_s.split("/")
          while pieces.size > 0 && (@branch.nil? || @branch.size == 0)
            @branch = pieces.shift
          end
          @only_path = pieces * "/"
          @path      = value
        end
        
        def revision_for(commit)
          @repository.revision_for(commit)
        end
        
        def collect_diffs(&block)
          diffs.inject [] do |collected, diff|
            block.call(diff) ? collected << diff.a_path : collected
          end
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
        Grit::Blob.blame(backend, node.revision, node.only_path).each do |(commit, lines)|
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
        File.join(@options[:path], node.only_path)
      end
      
      def find_commit(id)
        cached_commits[id] ||= backend.commit(id)
      end
      
      def latest_commit_for(node)
        cached_commits[[node.branch, node.only_path]] ||= backend.log(node.branch, node.only_path, :max_count => 1).first
      end
      
      def revision_for(commit)
        commit ? commit.id : nil
      end

      def unified_diff_for(old_rev, new_rev, diff_path)
        new_rev = new_rev.revision if new_rev.respond_to?(:revision)
        old_rev = old_rev.revision if old_rev.respond_to?(:revision)
        old_rev = find_commit(new_rev).parents.first.to_s if old_rev.nil?
        diff    = Grit::Commit.diff(backend, old_rev, new_rev, Array(diff_path)).collect do |d|
          next '' unless d.a_path[diff_path]
          a_id = d.a_commit ? d.a_commit.id[0..6] : '0000000'
          b_id = d.b_commit ? d.b_commit.id[0..6] : '0000000'
          "diff --git a/#{d.a_path} b/#{d.b_path}\nindex #{a_id}..#{b_id}\n#{d.diff}"
        end
        [old_rev, new_rev, diff * "\n"]
      end

      def tree(*args)
        backend && backend.tree(*args)
      end
      
      def cached_commits
        @cached_commits ||= {}
      end
      
      def cached_diffs
        @cached_diffs ||= {}
      end
    
    protected
      def backend
        @backend ||= @options[:path].to_s.size.zero? ? nil : Grit::Repo.new(@options[:path].to_s)
      end
    end
  end
end