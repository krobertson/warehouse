module Warehouse
  module Syncer
    class GitSyncer < Base

      def process
        super do |authors|
          latest_changeset = @connection[:changesets].where(:repository_id => @repo[:id]).order(:changed_at.DESC).first
          latest_rev       = @silo.latest_revision
          branch_prefix    = @repo[:synced_revision].to_s.size.zero? ? '' : @repo[:synced_revision] + ".."
          revisions        = @silo.send(:backend).git.rev_list({}, @silo.send(:backend).heads.collect { |h| branch_prefix + h.name }).split
          revisions.reverse!
          @connection.transaction do    
            i = 0
            while (@num.zero? || i < @num) && rev = revisions.shift
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
    end
  end
end