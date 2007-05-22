class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.integer :repository_id
      t.integer :user_id
      t.boolean :active
      t.boolean :full_access
      t.string :path
    end
  end

  def self.down
    drop_table :permissions
  end
end
