class MoveLoginToUser < ActiveRecord::Migration
  def self.up
    add_column "users", "login", :string
    Permission.find(:all, :select => "distinct user_id, login", :conditions => 'user_id is not null').each do |perm|
      user = User.find_by_id perm.user_id
      next if user.nil?
      user.update_attribute :login, perm.login
    end
    remove_column "permissions", "login"
    remove_column "users", "name"
  end

  def self.down
    remove_column "users", "login"
    add_column "permissions", "login", :string
    add_column "users", "name", :string
  end
end
