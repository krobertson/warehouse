class AddDiffableToChanges < ActiveRecord::Migration
  def self.up
    add_column :changes, :diffable, :boolean, :default => false
  end

  def self.down
    remove_column :changes, :diffable
  end
end
