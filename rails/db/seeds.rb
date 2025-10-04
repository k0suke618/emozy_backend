# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# assets/imagesにファイルを保存
# post: assets/images/posts/
# 
## Faker gemを使ってダミーデータを生成できるようにします
# Gemfileに gem 'faker', '~> 2.22.0' を追加し、bundle installしてください

require 'faker'

# ----------------------------------------------------
# 1. ユーザー関連の初期データ
# ----------------------------------------------------

# 背景画像を読み込み
puts 'Creating BackgroundImages...'
background_image_dir = Rails.root.join('public', 'assets', 'icon_maker', 'background')
if Dir.exist?(background_image_dir)
  Dir.children(background_image_dir).select { |f| f.match?(/\.(png|jpg|jpeg|gif)$/i) }.each do |filename|
    relative_path = File.join('public', 'assets', 'icon_maker', 'background', filename)
    db_path = File.join('rails', relative_path)
    BackgroundImage.find_or_create_by!(image: db_path, point: 50)
  end
else
  puts "Warning: Background image directory not found: #{background_image_dir}"
end

# フレーム画像を読み込み
puts 'Creating FrameImages...'
frame_image_dir = Rails.root.join('public', 'assets', 'icon_maker', 'frame')
if Dir.exist?(frame_image_dir)
  Dir.children(frame_image_dir).select { |f| f.match?(/\.(png|jpg|jpeg|gif)$/i) }.each do |filename|
    relative_path = File.join('public', 'assets', 'icon_maker', 'frame', filename)
    db_path = File.join('rails', relative_path)
    FrameImage.find_or_create_by!(image: db_path, point: 50)
  end
else
  puts "Warning: Frame image directory not found: #{frame_image_dir}"
end
puts 'BackgroundImages and FrameImages created successfully!'

# アイコン画像を10件作成
puts 'Creating IconImages...'
10.times do |n|
  IconImage.find_or_create_by!(image: "icon_#{n}.jpg", point: rand(100..500))
end
puts 'IconImages created successfully!'

# ユーザーを10人作成
puts 'Creating Users...'
10.times do |n|
  User.find_or_create_by!(email: "test#{n+1}@example.com") do |user|
    user.name = Faker::Name.name
    user.password = 'password'
    user.password_confirmation = 'password'
    user.point = rand(1000..5000)
    user.profile = Faker::Lorem.sentence
  end
end
puts 'Users created successfully!'

# ----------------------------------------------------
# 2. トピックと投稿の初期データ
# ----------------------------------------------------

# トピックを5件作成
puts 'Creating Topics...'
5.times do |n|
  Topic.find_or_create_by!(content: "話題#{n+1}")
end
puts 'Topics created successfully!'

# ユーザーとトピックを使って投稿を50件作成
puts 'Creating Posts...'
users = User.all
topics = Topic.all
posts_image_dir = Rails.root.join('public', 'assets', 'posts', 'images')
posts_image_paths = if Dir.exist?(posts_image_dir)
                      Dir.children(posts_image_dir).map { |filename| File.join('assets', 'posts', 'images', filename) }
                    else
                      []
                    end
50.times do
  image_path = (posts_image_paths + [nil]).sample
  Post.create!(
    user: users.sample,
    topic: topics.sample,
    content: Faker::Lorem.paragraph,
    image: image_path,
    is_set_reaction_1: true # デフォルトでリアクション1を有効にする
  )
end
puts 'Posts created successfully!'

# ----------------------------------------------------
# 3. リアクション関連の初期データ
# ----------------------------------------------------

# リアクションの種類を作成
puts 'Creating Reactions...'
[
  { name: 'Like', image: 'like.png' },
  { name: 'Love', image: 'love.png' },
  { name: 'Wow', image: 'wow.png' },
  { name: 'Laugh', image: 'laugh.png' }
].each do |attrs|
  Reaction.find_or_create_by!(attrs)
end
puts 'Reactions created successfully!'

# 各投稿に対してランダムにリアクションを付与
puts 'Creating PostReactions...'
posts = Post.all
posts.each do |post|
  # 各投稿に対して、is_set_reaction_nに基づいてPostReactionを作成
  (1..12).each do |i|
    if post.send("is_set_reaction_#{i}")
      reaction = Reaction.find_by(id: i)
      if reaction
        PostReaction.find_or_create_by!(
          user: users.sample,
          post: post,
          reaction: reaction
        )
      end
    end
  end
end
puts 'PostReactions created successfully!'

# ----------------------------------------------------
# 4. アイテム所有の初期データ
# ----------------------------------------------------

# 各ユーザーにアイコン画像をランダムに付与（背景・フレームは初期状態で未所持）
puts 'Assigning items to users...'
users.each do |user|
  # 背景・フレームの所有情報をリセット
  BackgroundList.where(user: user).delete_all
  FrameList.where(user: user).delete_all

  IconImage.all.sample(rand(2..5)).each do |icon_image|
    IconImageList.find_or_create_by!(user: user, image: icon_image)
  end

  # 背景・フレームは未設定のままにする
  user.background = nil
  user.frame = nil
  UserIcon.find_or_create_by!(user: user) do |user_icon|
    user_icon.icon_image = IconImage.all.sample
  end
  user.save!
end
puts 'Items assigned successfully!'

# ----------------------------------------------------
# 5. フォロー、お気に入り、ポイント、レポートの初期データ
# ----------------------------------------------------

puts 'Creating Follows, Favorites, Points, and Reports...'
posts = Post.all
topics = Topic.all
point_type_map = {
  'ログインボーナス' => PointType.find_or_create_by!(content: 'ログインボーナス'),
  '投稿' => PointType.find_or_create_by!(content: '投稿'),
  'リアクション獲得' => PointType.find_or_create_by!(content: 'リアクション獲得')
}

point_templates = {
  'ログインボーナス' => [50, 100, 150],
  '投稿' => [10, 20, 30],
  'リアクション獲得' => [5, 8, 12]
}

points_by_type = point_templates.each_with_object({}) do |(content, values), hash|
  point_type = point_type_map.fetch(content)
  hash[content] = values.map do |value|
    Point.find_or_create_by!(point_type: point_type, value: value)
  end
end

report_types = [
  ReportType.find_or_create_by!(content: 'スパム'),
  ReportType.find_or_create_by!(content: '不適切なコンテンツ'),
]

users.each do |user|
  # フォロー関係を作成
  users.sample(rand(1..3)).each do |followed_user|
    Follow.find_or_create_by!(follower: user, followed: followed_user)
  end

  # お気に入りを作成
  posts.sample(rand(1..10)).each do |post|
    Favorite.find_or_create_by!(user: user, post: post, topic: post.topic)
  end

  # ポイント履歴を作成
  point_type_map.each_key do |content|
    rand(1..3).times do
      template_point = points_by_type.fetch(content).sample
      UserPoint.create!(user: user, point: template_point, value: template_point.value)
    end
  end
  
  # レポートを作成
  posts.sample(rand(0..2)).each do |post|
    Report.find_or_create_by!(user: user, post: post, report_type: report_types.sample, content: Faker::Lorem.sentence)
  end
end
puts 'Follows, Favorites, Points, and Reports created successfully!'

# ----------------------------------------------------
# 6. icon parts type を設定
# ----------------------------------------------------
puts 'Creating IconPartTypes...'
icon_part_types = [
  "eyes",
  "mouth",
  "skin",
  "front_hair",
  "back_hair",
  "eyebrows",
  "high_light",
  "clothing",
  "accessory",
]

# IconPartsTypeテーブルにデータを追加
# すでに存在する場合はスキップ
# contentカラムに保存
icon_part_types.each do |type|
  IconPartsType.find_or_create_by!(content: type)
end
puts 'IconPartTypes created successfully!'

puts 'Seed data has been successfully created!'
