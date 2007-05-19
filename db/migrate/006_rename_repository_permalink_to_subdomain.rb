class RenameRepositoryPermalinkToSubdomain < ActiveRecord::Migration
  def self.up
    rename_column :repositories, :permalink, :subdomain
  end

  def self.down
    rename_column :repositories, :subdomain, :permalink
  end
end
