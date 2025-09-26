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

# 背景画像とフレーム画像を10件ずつ作成
puts 'Creating BackgroundImages and FrameImages...'
10.times do |n|
  BackgroundImage.find_or_create_by!(image: "background_#{n}.jpg", point: rand(100..500))
  FrameImage.find_or_create_by!(image: "frame_#{n}.jpg", point: rand(100..500))
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
50.times do
  Post.create!(
    user: users.sample,
    topic: topics.sample,
    content: Faker::Lorem.paragraph,
    image: [Faker::Lorem.word + '.jpg', nil].sample # 投稿には画像があってもなくてもよい
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
reactions = Reaction.all
posts.each do |post|
  # 各投稿にランダムな数のリアクションを付ける
  rand(1..5).times do
    PostReaction.find_or_create_by!(
      user: users.sample,
      post: post,
      reaction: reactions.sample
    )
  end
end
puts 'PostReactions created successfully!'

# ----------------------------------------------------
# 4. アイテム所有の初期データ
# ----------------------------------------------------

# 各ユーザーに背景画像とフレーム画像、アイコン画像をランダムに付与
puts 'Assigning items to users...'
users.each do |user|
  BackgroundImage.all.sample(rand(2..5)).each do |bg_image|
    BackgroundList.find_or_create_by!(user: user, image: bg_image)
  end
  FrameImage.all.sample(rand(2..5)).each do |frame_image|
    FrameList.find_or_create_by!(user: user, image: frame_image)
  end
  IconImage.all.sample(rand(2..5)).each do |icon_image|
    IconImageList.find_or_create_by!(user: user, image: icon_image)
  end

  # 各ユーザーにランダムな背景・フレーム・アイコンを設定
  user.background = BackgroundImage.all.sample
  user.frame = FrameImage.all.sample
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
    template_point = points_by_type.fetch(content).sample
    UserPoint.find_or_create_by!(user: user, point: template_point) do |user_point|
      user_point.value = template_point.value
    end
  end
  
  # レポートを作成
  posts.sample(rand(0..2)).each do |post|
    Report.find_or_create_by!(user: user, post: post, report_type: report_types.sample, content: Faker::Lorem.sentence)
  end
end
puts 'Follows, Favorites, Points, and Reports created successfully!'

puts 'Seed data has been successfully created!'
