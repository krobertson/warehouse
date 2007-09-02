class AddDiffableToChangesets < ActiveRecord::Migration
  def self.up
    add_column :changesets, :diffable, :boolean
  end

  def self.down
    remove_column :changesets, :diffable
  end
end
