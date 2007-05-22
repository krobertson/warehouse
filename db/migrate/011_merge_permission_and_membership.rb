class MergePermissionAndMembership < ActiveRecord::Migration
  def self.up
    drop_table :permissions
    add_column "memberships", "path", :string
    add_column "memberships", "full_access", :boolean
  end

  def self.down
    create_table :permissions do |t|
      t.integer :repository_id
      t.integer :user_id
      t.boolean :active
      t.boolean :full_access
      t.string :path
    end
    remove_column "memberships", "path"
    remove_column "memberships", "full_access"
  end
end
