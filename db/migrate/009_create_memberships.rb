class CreateMemberships < ActiveRecord::Migration
  def self.up
    create_table :memberships do |t|
      t.integer :user_id
      t.integer :repository_id
      t.boolean :active
      t.boolean :admin
      t.string :login
    end
    add_column "users", "email", :string
    add_column "users", "token", :string
  end

  def self.down
    drop_table :memberships
    remove_column "users", "email"
    remove_column "users", "token"
  end
end
