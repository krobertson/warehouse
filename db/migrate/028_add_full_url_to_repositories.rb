class AddFullUrlToRepositories < ActiveRecord::Migration
  def self.up
    add_column "repositories", "full_url", :string
  end

  def self.down
    remove_column "repositories", "full_url"
  end
end
