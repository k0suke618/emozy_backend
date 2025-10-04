class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include ImageUrlHelper # ImageUrlHelperも必要なのでincludeします

  private

  # 全データに対して画像URLとリアクション数を追加するためのヘルパーメソッド
  def serialize_post(post)
    {
      id:                   post.id,
      user_id:              post.user_id,
      name:                 post.name,
      topic_id:             post.topic_id,
      content:              post.content,
      image_url:            build_image_url(post.image),
      num_reactions:        get_num_reactions(post),
      reacted_reaction_ids: @current_user_id ? post.post_reactions.where(user_id: @current_user_id).pluck(:reaction_id) : [],
      is_favorited:         @current_user_id ? Favorite.exists?(user_id: @current_user_id, post_id: post.id) : false,
      created_at:           post.created_at,
      updated_at:           post.updated_at
    }
  end

  # 投稿に紐づくリアクション数を取得するメソッド
  def get_num_reactions(post)
    # リアクションの種類ごとにカウントする
    counts = {}
    (1..12).each do |i|
      if post.send("is_set_reaction_#{i}")
        counts[i] = post.post_reactions.where(reaction_id: i).count
      end
    end
    counts
  end

  # (posts_controllerにある他のヘルパーメソッドも必要に応じて移動)
  # save_base64_image, detect_image_extension など
end
