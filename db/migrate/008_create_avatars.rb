class CreateAvatars < ActiveRecord::Migration
  def self.up
    create_table :avatars do |t|
      t.string :content_type
      t.string :filename
      t.integer :size
      t.integer :parent_id
      t.string :thumbnail
      t.integer :width
      t.integer :height
    end
    add_column "users", "avatar_id", :integer
    add_column "users", "avatar_path", :string
  end

  def self.down
    drop_table :avatars
    remove_column "users", "avatar_id"
    remove_column "users", "avatar_path"
  end
end
