module Api
  module V1
    class SearchController < ApplicationController
      protect_from_forgery with: :null_session
      
      # POST /api/v1/search
      def index
        # keyword検索API
        # 検索対象
        # user: name (keywordを含むuserを取得)
        # post: content (keywordを含むpostを取得)
        # topic: content (topic contentからtopic idを取得、そのtopic idを持つpostを取得)
        keyword = search_params[:keyword]
        if keyword.blank?
          render json: { error: "Keyword is required" }, status: :bad_request
          return
        end
        # user nameを検索
        users = search_users(keyword)
        # user profileを検索して追加
        users = users.or(search_user_profile(keyword)).distinct
        # post contentを検索
        posts = search_posts(keyword)
        # topic contentを検索して追加
        posts = posts.or(search_topics(keyword)).distinct
        render_json({ users: users, posts: posts })
      end

    private
      def search_users(keyword)
        User.where("name LIKE ?", "%#{keyword}%")
      end

      def search_user_profile(keyword)
        User.where("profile LIKE ?", "%#{keyword}%")
      end

      def search_posts(keyword)
        Post.where("content LIKE ?", "%#{keyword}%")
      end

      def search_topics(keyword)
        topic_ids = Topic.where("content LIKE ?", "%#{keyword}%").pluck(:id)
        Post.where(topic_id: topic_ids)
      end

      def render_json(data, status: :ok)
        render json: data, status: status
      end

      def search_params
        params.require(:search).permit(:keyword)
      end
    end
  end
end
