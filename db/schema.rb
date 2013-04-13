# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130401134659) do

  create_table "assignments", :force => true do |t|
    t.integer  "mark_id"
    t.integer  "package_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "brew_tags", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.string   "can_show"
    t.integer  "total_manual_track_time"
  end

  create_table "changelogs", :force => true do |t|
    t.integer  "package_id"
    t.integer  "changed_by"
    t.string   "category"
    t.string   "references"
    t.text     "from_value"
    t.text     "to_value"
    t.datetime "changed_at"
  end

  create_table "comments", :force => true do |t|
    t.string   "title",            :limit => 50, :default => ""
    t.text     "comment",                        :default => ""
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "source"
  end

  add_index "comments", ["commentable_id"], :name => "index_comments_on_commentable_id"
  add_index "comments", ["commentable_type"], :name => "index_comments_on_commentable_type"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "component_views", :force => true do |t|
    t.integer "component_id"
    t.integer "brew_tag_id"
  end

  create_table "components", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "components_packages", :force => true do |t|
    t.integer "component_id"
    t.integer "package_id"
  end

  create_table "labels", :force => true do |t|
    t.string   "name"
    t.integer  "brew_tag_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "global"
    t.string   "can_select"
    t.string   "can_show"
    t.string   "code"
    t.text     "style"
    t.string   "is_track_time"
  end

  create_table "marks", :force => true do |t|
    t.string   "key"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "brew_tag_id"
  end

  create_table "p_attachments", :force => true do |t|
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "package_id"
    t.integer  "created_by"
  end

  create_table "package_relationships", :force => true do |t|
    t.integer  "from_package_id"
    t.integer  "to_package_id"
    t.integer  "relationship_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "packages", :force => true do |t|
    t.string   "name"
    t.string   "build"
    t.text     "notes"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "brew_tag_id"
    t.integer  "label_id"
    t.integer  "created_by"
    t.string   "version"
    t.string   "ver"
    t.string   "brew_link"
    t.string   "group_id"
    t.string   "artifact_id"
    t.string   "project_url"
    t.string   "project_name"
    t.string   "license"
    t.string   "internal_scm"
    t.integer  "updated_by"
    t.datetime "label_changed_at"
    t.string   "external_scm"
    t.string   "mead"
    t.integer  "time_consumed"
    t.integer  "time_point"
  end

  create_table "relationships", :force => true do |t|
    t.string   "from_name"
    t.string   "is_global"
    t.integer  "brew_tag_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "to_name"
    t.string   "name"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "settings", :force => true do |t|
    t.text     "recipients"
    t.integer  "props"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "brew_tag_id"
    t.integer  "actions"
    t.text     "xattrs"
    t.string   "show_xattrs"
    t.string   "enabled"
    t.string   "enable_xattrs"
    t.string   "default_tag"
  end

  create_table "track_times", :force => true do |t|
    t.integer "label_id"
    t.integer "package_id"
    t.integer "time_consumed"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "brew_link"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "can_manage"
  end

  create_table "versions", :force => true do |t|
    t.integer  "versioned_id"
    t.string   "versioned_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "user_name"
    t.text     "changes"
    t.integer  "number"
    t.string   "tag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "versions", ["created_at"], :name => "index_versions_on_created_at"
  add_index "versions", ["number"], :name => "index_versions_on_number"
  add_index "versions", ["tag"], :name => "index_versions_on_tag"
  add_index "versions", ["user_id", "user_type"], :name => "index_versions_on_user_id_and_user_type"
  add_index "versions", ["user_name"], :name => "index_versions_on_user_name"
  add_index "versions", ["versioned_id", "versioned_type"], :name => "index_versions_on_versioned_id_and_versioned_type"

end
