class CreateChanges < ActiveRecord::Migration
  def self.up
    create_table :changes do |t|
      t.integer :changeset_id
      t.string :name
      t.text :path
      t.text :from_path
      t.integer :from_revision
    end
    
    add_index :changes, :changeset_id
  end

  def self.down
    drop_table :changes
    remove_index :changes, :changeset_id
  end
end
