class AddUserIndexes < ActiveRecord::Migration
  def self.up
    add_index :users, :token
    add_index :users, :email
  end

  def self.down
    remove_index :users, :token
    remove_index :users, :email
  end
end
