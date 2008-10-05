module Warehouse
  module Syncer
    class GitSyncer < Base

      def process
        super do |authors|
          latest_changeset = @connection[:changesets].where(:repository_id => @repo[:id]).order(:changed_at.DESC).first
          latest_rev       = @silo.latest_revision
          @heads           = @silo.send(:backend).heads.collect { |h| h.name }
          if @heads.include?('master')
            @heads.delete 'master'
            @heads.unshift 'master'
          end
          arguments = @heads.dup
          arguments << "--since=#{(@repo[:synced_changed_at]+1).xmlschema}" if @repo[:synced_changed_at]
          revisions = @silo.send(:backend).git.rev_list({}, *arguments).split
          revisions.reverse!
          @connection.transaction do    
            i = 0
            while (@num.zero? || i < @num) && revisions.size > 0
              rev = revisions.shift
              changeset = create_changeset(rev)
              if i > 1 && i % 100 == 0
                update_repository_progress rev, changeset, 100
                @connection.execute "COMMIT"
                @connection.execute "BEGIN"
                i = -1
                puts "##{rev}", :debug
              end
              authors[changeset[:author]] = changeset[:changed_at]
              i += 1
            end
            update_repository_progress rev, changeset, i
          end
        end
      end
      
#    protected
#      def process_change_path_and_save(node, path, changeset, name, diff_node, changes)
#        orig_path = diff_node.path
#        super unless @heads.detect do |head|
#          diff_node = node.repository.node_at("#{head}/#{orig_path}", node.revision)
#          diff_node.exists?
#        end.nil?
#      end
    end
  end
end