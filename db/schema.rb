# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 28) do

  create_table "avatars", :force => true do |t|
    t.string  "content_type"
    t.string  "filename"
    t.integer "size"
    t.integer "parent_id"
    t.string  "thumbnail"
    t.integer "width"
    t.integer "height"
  end

  create_table "bookmarks", :force => true do |t|
    t.integer "repository_id"
    t.string  "path"
    t.string  "label"
    t.text    "description"
  end

  add_index "bookmarks", ["repository_id"], :name => "index_bookmarks_on_repository_id"

  create_table "changes", :force => true do |t|
    t.integer "changeset_id"
    t.string  "name"
    t.text    "path"
    t.text    "from_path"
    t.integer "from_revision"
  end

  add_index "changes", ["changeset_id"], :name => "index_changes_on_changeset_id"

  create_table "changesets", :force => true do |t|
    t.string   "author"
    t.text     "message"
    t.datetime "changed_at"
    t.integer  "repository_id"
    t.string   "revision"
    t.boolean  "diffable"
  end

  add_index "changesets", ["repository_id"], :name => "index_changesets_on_repository_id"
  add_index "changesets", ["repository_id", "author"], :name => "idx_changesets_on_repo_id_and_author"
  add_index "changesets", ["repository_id", "changed_at"], :name => "index_changesets_on_repository_id_and_changed_at"

  create_table "hooks", :force => true do |t|
    t.integer  "repository_id"
    t.string   "name"
    t.text     "options"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active"
    t.string   "label"
  end

  create_table "open_id_authentication_associations", :force => true do |t|
    t.binary  "server_url"
    t.string  "handle"
    t.binary  "secret"
    t.integer "issued"
    t.integer "lifetime"
    t.string  "assoc_type"
  end

  create_table "open_id_authentication_nonces", :force => true do |t|
    t.string  "nonce"
    t.integer "created"
  end

  create_table "open_id_authentication_settings", :force => true do |t|
    t.string "setting"
    t.binary "value"
  end

  create_table "permissions", :force => true do |t|
    t.integer  "user_id"
    t.integer  "repository_id"
    t.boolean  "active"
    t.boolean  "admin"
    t.string   "path"
    t.boolean  "full_access"
    t.integer  "changesets_count", :default => 0
    t.datetime "last_changed_at"
  end

  add_index "permissions", ["repository_id", "active"], :name => "index_permissions_on_repository_id"

  create_table "plugins", :force => true do |t|
    t.string   "name"
    t.text     "options"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "repositories", :force => true do |t|
    t.string  "name"
    t.string  "path"
    t.string  "subdomain"
    t.boolean "public"
    t.string  "full_url"
  end

  add_index "repositories", ["subdomain"], :name => "index_repositories_on_subdomain"
  add_index "repositories", ["public"], :name => "index_repositories_on_public"

  create_table "users", :force => true do |t|
    t.string  "identity_url"
    t.boolean "admin"
    t.integer "avatar_id"
    t.string  "avatar_path"
    t.string  "email"
    t.string  "token"
    t.string  "login"
    t.string  "crypted_password"
  end

  add_index "users", ["token"], :name => "index_users_on_token"
  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["login"], :name => "index_users_on_login"

end
