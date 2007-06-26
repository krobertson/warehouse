class AddCryptedPassword < ActiveRecord::Migration
  def self.up
    add_column "users", "crypted_password", :string
    add_index :users, :login
  end

  def self.down
    remove_column "users", "crypted_password"
    remove_index :users, :login
  end
end
