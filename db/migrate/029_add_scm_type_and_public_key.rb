class AddScmTypeAndPublicKey < ActiveRecord::Migration
  class Repository < ActiveRecord::Base; end

  def self.up
    add_column :repositories, :scm_type, :string, :default => 'svn'
    add_column :users, :public_key, :text
    Repository.update_all ['scm_type = ?', 'svn']
  end

  def self.down
    remove_column :repositories, :scm_type
    remove_column :users, :public_key
  end
end
