class CreateChangesets < ActiveRecord::Migration
  def self.up
    create_table :changesets do |t|
      t.integer :revision
      t.string :author
      t.text :message
      t.datetime :changed_at
      t.integer :repository_id
    end
    
    add_index :changesets, :repository_id
  end

  def self.down
    drop_table :changesets
    remove_index :changesets, :repository_id
  end
end
