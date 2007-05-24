class AddIndexes < ActiveRecord::Migration
  def self.up
    remove_index :changesets, :name => 'index_changesets_on_repository_id'
    add_index :changesets, [:repository_id, :revision], :name => 'index_changesets_on_repository_id'
    add_index :permissions, [:repository_id, :active], :name => 'index_permissions_on_repository_id'
  end

  def self.down
  end
end
