module Api
  module V1
    class SearchController < ApplicationController
      protect_from_forgery with: :null_session
      
      # POST /api/v1/search
      def index
        # keyword検索API
        # 検索対象
        # user: name (keywordを含むuserを取得), profile (keywordを含むuser profileを取得)
        # post: content (keywordを含むpostを取得)
        # topic: content (topic contentからtopic idを取得、そのtopic idを持つpostを取得)
        # reaction_idで絞り込み可能 (reaction_idを持つpostのみ取得)
        keyword = search_params[:keyword]
        reaction_id = search_params[:reaction_id]
        if keyword.blank? and reaction_id.blank?
          render json: { error: "Keyword or Reaction ID is required" }, status: :bad_request
          return
        end
        # keywordが空文字の場合はusersを無視
        if keyword.blank?
          if reaction_id.present?
            posts = search_reaction(reaction_id).distinct
            render_json({ users: [], posts: posts })
            return
          end
        end
        # user nameを検索
        users = search_users(keyword)
        # user profileを検索して追加
        users = users.or(search_user_profile(keyword)).distinct
        # post contentを検索
        posts = search_posts(keyword)
        # topic contentを検索して追加
        posts = posts.or(search_topics(keyword)).distinct
        # reaction_idが指定されていればリアクションで絞り込み
        if reaction_id.present?
          posts = posts.merge(search_reaction(reaction_id))
        end
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

      def search_reaction(reaction_id)
        index = reaction_id.to_i
        return Post.none unless index.positive? && index <= 12

        Post.where("is_set_reaction_#{index} = ?", true)
      end

      def render_json(data, status: :ok)
        render json: data, status: status
      end

      def search_params
        params.require(:search).permit(:keyword, :reaction_id)
      end
    end
  end
end
