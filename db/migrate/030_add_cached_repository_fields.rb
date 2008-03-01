class AddCachedRepositoryFields < ActiveRecord::Migration
  class Changeset < ActiveRecord::Base
  end
  class Repository < ActiveRecord::Base
  end

  def self.up
    add_column :repositories, :synced_changed_at, :datetime
    add_column :repositories, :synced_revision, :string
    add_column :repositories, :changesets_count, :integer, :default => 0
    Repository.find(:all).each do |repo|
      synced, count = 
        Changeset.send :with_scope, :find => {:conditions => {:repository_id => repo.id}} do
          [Changeset.find(:first, :order => 'changed_at desc'), Changeset.count(:id)]
        end
      Repository.update_all ['synced_changed_at = ?, synced_revision = ?, changesets_count = ?',
        synced.changed_at, synced.revision, count
        ], ['id = ?', repo.id] if synced
    end
  end

  def self.down
    remove_column :repositories, :synced_changed_at
    remove_column :repositories, :synced_revision
    remove_column :repositories, :changesets_count
  end
end
