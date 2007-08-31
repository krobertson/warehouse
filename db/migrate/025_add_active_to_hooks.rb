class AddActiveToHooks < ActiveRecord::Migration
  def self.up
    add_column :hooks, :active, :boolean
  end

  def self.down
    remove_column :hooks, :active
  end
end
