module Importer
  module MysqlAdapter
    class Repository < Base
      table 'repositories'
      
      def recorded_revision(refresh = false)
        if @recorded_revision == nil || refresh
          changeset = Changeset.find_first("repository_id = #{quote_string attributes['id']} ORDER BY changesets.revision desc")
          @recorded_revision = (changeset ? changeset.attributes['revision'] : 0).to_i + 1
        end
        @recorded_revision
      end

      def latest_revision
        @latest_revision ||= backend.youngest_rev
      end

      def sync_revisions(num = 0)
        transaction do
          revisions = (recorded_revision..latest_revision).to_a
          if num > 0
            revisions = revisions[0..num-1]
          end
          revisions.collect do |rev|
            puts "##{rev}"
            Changeset.create_from_repository(self, rev)
          end
        end
      end

      def sync_all_revisions!
        clear_revisions!
        sync_revisions
      end
      
      def clear_revisions!
        Changeset.delete_all "WHERE repository_id = #{quote_string attributes['id']}"
        Change.delete_all "USING changes, changesets WHERE changes.changeset_id = changesets.id AND changesets.repository_id = #{quote_string attributes['id']}"
      end

      def backend
        @backend ||= Svn::Repos.open(attributes['path'])
      end
    end
  end
end