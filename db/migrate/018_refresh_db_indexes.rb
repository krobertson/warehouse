class RefreshDbIndexes < ActiveRecord::Migration
  def self.up
    add_index :repositories, :subdomain
    add_index :repositories, :public
  end

  def self.down
    remove_index :repositories, :subdomain
    remove_index :repositories, :public
  end
end
