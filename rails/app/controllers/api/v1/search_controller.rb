module Api
  module V1
    # ApplicationControllerを継承するように変更
    class SearchController < ApplicationController
      include ImageUrlHelper
      protect_from_forgery with: :null_session
      
      def index
        # 現在のユーザーIDを取得
        @current_user_id = search_params[:user_id].presence&.to_i

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
        serialized_posts = posts.distinct.map { |p| serialize_post(p) }
        posts = posts.includes(:user)
        render_json({ users: [], posts: serialized_posts })
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
        post.as_json.merge(
          'image_url' => build_image_url(post.image),
          'icon_image_url' => resolve_user_icon_url(post.user)
        )
      end

      def resolve_user_icon_url(user)
        return nil unless user

        url = user.icon_image_url
        return nil if url.blank?

        url.start_with?('http://', 'https://') ? url : build_image_url(url)
      end

      def serialize_user(user)
        user.as_json.merge('icon_image_url' => resolve_user_icon_url(user))
      end

      def serialize_post(post)
        post.as_json.merge(
          'image_url' => build_image_url(post.image),
          'icon_image_url' => resolve_user_icon_url(post.user)
        )
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