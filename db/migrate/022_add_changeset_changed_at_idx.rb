class AddChangesetChangedAtIdx < ActiveRecord::Migration
  def self.up
    add_index :changesets, [:repository_id, :changed_at]
  end

  def self.down
    remove_index :changesets, [:repository_id, :changed_at]
  end
end
