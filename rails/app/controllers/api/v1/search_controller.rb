module Api
  module V1
    # ApplicationControllerを継承するように変更
    class SearchController < ApplicationController
      include ImageUrlHelper
      protect_from_forgery with: :null_session
      
      def index
        # 現在のユーザーIDを取得
        @current_user_id = search_params[:user_id].presence&.to_i

        # 現在のユーザーのお気に入り投稿IDを事前取得（N+1問題回避）
        @favorited_post_ids = @current_user_id ? Favorite.where(user_id: @current_user_id).pluck(:post_id).to_set : Set.new

        keyword = search_params[:keyword]
        reaction_id = search_params[:reaction_id]
        if keyword.blank? and reaction_id.blank?
          render json: { error: "Keyword or Reaction ID is required" }, status: :bad_request
          return
        end

        posts = Post.all

        # キーワードがあればユーザー名 or 投稿内容で絞り込み
        if keyword.present?
          user_ids = User.where("name LIKE ?", "%#{keyword}%").pluck(:id)
          posts = posts.where("content LIKE ? OR user_id IN (?)", "%#{keyword}%", user_ids)
        end

        # リアクションIDがあれば、さらにAND条件で絞り込み
        if reaction_id.present?
          posts = posts.merge(search_reaction(reaction_id))
        end

        # 最終的なpostsをシリアライズして返す
        posts = posts.includes(:user, :post_reactions).distinct
        render_json({ users: [], posts: posts })
      end
    
    private
      # (search_users, search_postsなどのメソッドは変更なし)
      def search_users(keyword)
        User.where("name LIKE ?", "%#{keyword}%")
      end

      def search_posts(keyword)
        Post.where("content LIKE ?", "%#{keyword}%")
      end

      def search_topics(keyword)
        topic_ids = Topic.where("content LIKE ?", "%#{keyword}%").pluck(:id)
        Post.where(topic_id: topic_ids)
      end

      def search_reaction(reaction_id)
        index = reaction_id.to_i
        return Post.none unless index.positive? && index <= 12

        Post.where("is_set_reaction_#{index} = ?", true)
      end

      def render_json(data, status: :ok)
        render json: {
          users: Array(data[:users]).map { |user| serialize_user(user) },
          posts: Array(data[:posts]).map { |post| serialize_post(post) }
        }, status: status
      end

      def search_params
        # user_idを許可する
        params.require(:search).permit(:keyword, :reaction_id, :user_id)
      end

      def serialize_user(user)
        user.as_json.merge('icon_image_url' => resolve_user_icon_url(user))
      end

      def serialize_post(post)
        {
          id: post.id,
          user_id: post.user_id,
          name: post.name,
          topic_id: post.topic_id,
          content: post.content,
          image_url: build_image_url(post.image),
          num_reactions: get_num_reactions(post),
          reacted_reaction_ids: get_reacted_reaction_ids(post),
          is_favorited: is_favorited_by_current_user?(post),
          created_at: post.created_at,
          updated_at: post.updated_at,
          icon_image_url: resolve_user_icon_url(post.user)
        }
      end

      # 投稿に紐づくリアクション数を取得するメソッド
      def get_num_reactions(post)
        counts = {}
        (1..12).each do |i|
          if post.send("is_set_reaction_#{i}")
            counts[i] = post.post_reactions.where(reaction_id: i).count
          end
        end
        counts
      end

      # 現在のユーザーがリアクションした反応IDを取得
      def get_reacted_reaction_ids(post)
        return [] unless @current_user_id

        post.post_reactions
            .where(user_id: @current_user_id)
            .pluck(:reaction_id)
      end

      # 現在のユーザーがお気に入りしているかチェック
      def is_favorited_by_current_user?(post)
        return false unless @current_user_id

        @favorited_post_ids.include?(post.id)
      end

      def resolve_user_icon_url(user)
        return nil unless user

        url = user.icon_image_url
        return nil if url.blank?

        url.start_with?('http://', 'https://') ? url : build_image_url(url)
      end
    end
  end
end