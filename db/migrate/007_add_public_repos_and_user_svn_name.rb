class AddPublicReposAndUserSvnName < ActiveRecord::Migration
  def self.up
    add_column "repositories", "public", :boolean
    #add_column "users", "svn_login", :string
  end

  def self.down
    remove_column "repositories", "public"
    #remove_column "users", "svn_login"
  end
end
