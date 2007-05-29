class CreateBookmarks < ActiveRecord::Migration
  def self.up
    create_table :bookmarks do |t|
      t.integer :repository_id
      t.string :path
      t.string :label
      t.text :description
    end
    add_index :bookmarks, :repository_id
  end

  def self.down
    drop_table :bookmarks
    remove_index :bookmarks, :repository_id
  end
end
