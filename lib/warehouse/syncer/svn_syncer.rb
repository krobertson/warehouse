module Warehouse
  module Syncer
    class SvnSyncer < Base
      def process
        super do |authors|
          latest_changeset = @connection[:changesets].where(:repository_id => @repo[:id]).order(:changed_at.DESC).first
          recorded_rev     = latest_changeset ? latest_changeset[:revision].to_i : 0
          latest_rev       = @silo.latest_revision
          @connection.transaction do    
            i = 0
            rev = recorded_rev
            until rev >= latest_rev || (@num > 0 && i >= @num) do
              rev += 1
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