module Api
  module V1
    # ApplicationControllerを継承するように変更
    class SearchController < ApplicationController
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

        if keyword.blank?
          if reaction_id.present?
            posts = search_reaction(reaction_id).distinct
            # 投稿データをserialize_postで整形
            serialized_posts = posts.map { |p| serialize_post(p) }
            render_json({ users: [], posts: serialized_posts })
            return
          end
        end

        users = search_users(keyword).includes(:posts)
        users = users.or(search_user_profile(keyword).includes(:posts)).distinct

        posts = search_posts(keyword)
        posts = posts.or(search_topics(keyword)).distinct
        
        if reaction_id.present?
          posts = posts.merge(search_reaction(reaction_id))
        end

        # 投稿データをserialize_postで整形
        serialized_users = users.map do |user|
          user.as_json.merge(
            "posts" => user.posts.map { |p| serialize_post(p) }
          )
        end

        serialized_posts = posts.map { |p| serialize_post(p) }
        
        # usersに関連する投稿もシリアライズする必要がある場合、別途処理が必要ですが、
        # まずは投稿検索の結果から修正します。
        # usersのレスポンスは一旦そのままにします。
        render_json({ users: serialized_users, posts: serialized_posts })
      end
    
    private
      # (search_users, search_postsなどのメソッドは変更なし)
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
        # user_idを許可する
        params.require(:search).permit(:keyword, :reaction_id, :user_id)
      end
    end
  end
end