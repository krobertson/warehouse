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
        return if revisions.empty?
        puts "Syncing Revisions ##{revisions.first} - ##{revisions.last}"
        revisions.collect do |rev|
          if rev > 1 && rev % 100 == 0
            self.class.adapter.execute "COMMIT"
            self.class.adapter.execute "BEGIN"
            puts "##{rev}"
          end
          changeset = Changeset.create_from_repository(self, rev)
          authors[changeset.attributes['author']] = Time.now.utc
        end
        
        users = User.find_all_by_logins(authors.keys).inject({}) { |memo, user| memo.update(user.attributes['login'] => user.attributes['id']) }
        authors.each do |login, changed_at|
          next unless users[login]
          self.class.adapter.execute("UPDATE `permissions` SET changesets_count = (SELECT COUNT(id) FROM changesets WHERE repository_id = #{quote_string attributes['id']} AND author = #{quote_string login}), last_changed_at = #{changed_at.strftime("%Y-%m-%d %H:%M:%S").inspect} WHERE user_id = #{quote_string users[login]} AND repository_id = #{quote_string attributes['id']}")
        end
        puts revisions.last
      end
    end
    
    def users
      User.find_all("id IN (SELECT DISTINCT `user_id` FROM `permissions` WHERE `active` = 1 AND `repository_id` = #{quote_string attributes['id']})")
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