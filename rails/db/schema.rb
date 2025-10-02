# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_10_02_132952) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "background_images", force: :cascade do |t|
    t.string "image", null: false
    t.bigint "point", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "background_lists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "image_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["image_id"], name: "index_background_lists_on_image_id"
    t.index ["user_id"], name: "index_background_lists_on_user_id"
  end

  create_table "favorites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.bigint "topic_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_favorites_on_post_id"
    t.index ["topic_id"], name: "index_favorites_on_topic_id"
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "follows", force: :cascade do |t|
    t.bigint "follower_id", null: false
    t.bigint "followed_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id"], name: "index_follows_on_followed_id"
    t.index ["follower_id"], name: "index_follows_on_follower_id"
  end

  create_table "frame_images", force: :cascade do |t|
    t.string "image", null: false
    t.bigint "point", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "frame_lists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "image_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["image_id"], name: "index_frame_lists_on_image_id"
    t.index ["user_id"], name: "index_frame_lists_on_user_id"
  end

  create_table "icon_image_lists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "image_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["image_id"], name: "index_icon_image_lists_on_image_id"
    t.index ["user_id"], name: "index_icon_image_lists_on_user_id"
  end

  create_table "icon_images", force: :cascade do |t|
    t.string "image", null: false
    t.bigint "point", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "icon_parts", force: :cascade do |t|
    t.bigint "icon_parts_type_id", null: false
    t.string "image", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["icon_parts_type_id"], name: "index_icon_parts_on_icon_parts_type_id"
  end

  create_table "icon_parts_lists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "eyes_image", null: false
    t.string "mouth_image", null: false
    t.string "skin_image", null: false
    t.string "front_hair_image", null: false
    t.string "back_hair_image", null: false
    t.string "eyebrows_image", null: false
    t.string "high_light_image", null: false
    t.string "clothing_image", null: false
    t.string "accessory_image", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_icon_parts_lists_on_user_id"
  end

  create_table "icon_parts_types", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "point_types", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "points", force: :cascade do |t|
    t.bigint "point_type_id", null: false
    t.bigint "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["point_type_id"], name: "index_points_on_point_type_id"
  end

  create_table "post_reactions", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.bigint "reaction_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_post_reactions_on_post_id"
    t.index ["reaction_id"], name: "index_post_reactions_on_reaction_id"
    t.index ["user_id"], name: "index_post_reactions_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "topic_id", null: false
    t.text "content"
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_set_reaction_1", default: false, null: false
    t.boolean "is_set_reaction_2", default: false, null: false
    t.boolean "is_set_reaction_3", default: false, null: false
    t.boolean "is_set_reaction_4", default: false, null: false
    t.boolean "is_set_reaction_5", default: false, null: false
    t.boolean "is_set_reaction_6", default: false, null: false
    t.boolean "is_set_reaction_7", default: false, null: false
    t.boolean "is_set_reaction_8", default: false, null: false
    t.boolean "is_set_reaction_9", default: false, null: false
    t.boolean "is_set_reaction_10", default: false, null: false
    t.boolean "is_set_reaction_11", default: false, null: false
    t.boolean "is_set_reaction_12", default: false, null: false
    t.string "name"
    t.index ["topic_id"], name: "index_posts_on_topic_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "reactions", force: :cascade do |t|
    t.string "name", null: false
    t.string "image", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_reactions_on_name", unique: true
  end

  create_table "report_types", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reports", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.bigint "report_type_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_reports_on_post_id"
    t.index ["report_type_id"], name: "index_reports_on_report_type_id"
    t.index ["user_id"], name: "index_reports_on_user_id"
  end

  create_table "topics", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_icons", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "icon_image_id", null: false
    t.boolean "is_icon", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["icon_image_id"], name: "index_user_icons_on_icon_image_id"
    t.index ["user_id"], name: "index_user_icons_on_user_id"
  end

  create_table "user_points", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "point_id", null: false
    t.bigint "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["point_id"], name: "index_user_points_on_point_id"
    t.index ["user_id", "point_id"], name: "index_user_points_on_user_id_and_point_id"
    t.index ["user_id"], name: "index_user_points_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email", null: false
    t.text "profile"
    t.bigint "point", default: 0, null: false
    t.bigint "background_id"
    t.bigint "frame_id"
    t.string "password_digest", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["background_id"], name: "index_users_on_background_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["frame_id"], name: "index_users_on_frame_id"
  end

  add_foreign_key "background_lists", "background_images", column: "image_id"
  add_foreign_key "background_lists", "users"
  add_foreign_key "favorites", "posts"
  add_foreign_key "favorites", "topics"
  add_foreign_key "favorites", "users"
  add_foreign_key "follows", "users", column: "followed_id"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "frame_lists", "frame_images", column: "image_id"
  add_foreign_key "frame_lists", "users"
  add_foreign_key "icon_image_lists", "icon_images", column: "image_id"
  add_foreign_key "icon_image_lists", "users"
  add_foreign_key "icon_parts", "icon_parts_types"
  add_foreign_key "icon_parts_lists", "users"
  add_foreign_key "points", "point_types"
  add_foreign_key "post_reactions", "posts"
  add_foreign_key "post_reactions", "reactions"
  add_foreign_key "post_reactions", "users"
  add_foreign_key "posts", "topics"
  add_foreign_key "posts", "users"
  add_foreign_key "reports", "posts"
  add_foreign_key "reports", "report_types"
  add_foreign_key "reports", "users"
  add_foreign_key "user_icons", "icon_images"
  add_foreign_key "user_icons", "users"
  add_foreign_key "user_points", "points"
  add_foreign_key "user_points", "users"
  add_foreign_key "users", "background_images", column: "background_id"
  add_foreign_key "users", "frame_images", column: "frame_id"
end
