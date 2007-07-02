class ChangeRevisionToString < ActiveRecord::Migration
  def self.up
    rename_column :changesets, :revision, :revision_as_int
    add_column :changesets, :revision, :string
    Changeset.connection.execute "UPDATE changesets SET revision = revision_as_int"
    remove_column :changesets, :revision_as_int
  end

  def self.down
  end
end
