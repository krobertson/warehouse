class Rename < ActiveRecord::Migration
  def self.up
    rename_table :memberships, :permissions
  end

  def self.down
    rename_table :permissions, :memberships
  end
end
