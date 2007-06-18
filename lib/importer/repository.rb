module Importer
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
      self.class.transaction do
        authors = {}
        revisions = (recorded_revision..latest_revision).to_a
        if num > 0
          revisions = revisions[0..num-1]
        end
        puts "Syncing Revisions ##{revisions.first} - ##{revisions.last}"
        revisions.collect do |rev|
          puts "##{rev}" if rev > 1 && rev % 100 == 0
          changeset = Changeset.create_from_repository(self, rev)
          authors[changeset.attributes['author']] = Time.now.utc
        end
        
        authors.each do |login, changed_at|
          self.class.adapter.execute("UPDATE `permissions` SET changesets_count = (SELECT COUNT(id) FROM changesets WHERE repository_id = #{quote_string attributes['id']} AND author = #{quote_string login}), last_changed_at = #{changed_at.strftime("%Y-%m-%d %H:%M:%S").inspect} WHERE login = #{quote_string login} AND repository_id = #{quote_string attributes['id']}")
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