class AddChangesetAuthorCache < ActiveRecord::Migration
  def self.up
    add_index :changesets, [:repository_id, :author], :name => :idx_changesets_on_repo_id_and_author
    add_column "permissions", "changesets_count", :integer, :default => 0
    add_column "permissions", "last_changed_at", :datetime
  end

  def self.down
    remove_index :changesets, :name => :idx_changesets_on_repo_id_and_author
    remove_column "permissions", "changesets_count"
    remove_column "permissions", "last_changed_at"
  end
end
