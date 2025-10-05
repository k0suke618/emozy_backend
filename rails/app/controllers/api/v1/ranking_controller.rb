module Api
  module V1
    class RankingController < ApplicationController
      include ImageUrlHelper
      # CSRFトークン検証を無効化
      protect_from_forgery with: :null_session

      # GET /api/v1/ranking
      # 全体のランキングを取得
      def index
        @current_user_id = params[:user_id].presence&.to_i
        @favorited_post_ids = @current_user_id ? Favorite.where(user_id: @current_user_id).pluck(:post_id).to_set : Set.new
        fetch_and_render_ranking
      end

      # POST /api/v1/ranking
      # 特定のリアクションでのランキングを取得
      def create
        @current_user_id = params[:user_id].presence&.to_i
        @favorited_post_ids = @current_user_id ? Favorite.where(user_id: @current_user_id).pluck(:post_id).to_set : Set.new
        fetch_and_render_ranking(ranking_params)
      end

      private

      # ランキングデータを取得してJSONとして描画する共通メソッド
      def fetch_and_render_ranking(params = {})
        limit = extract_limit(params[:limit])
        scope = Post.joins(:user) # ユーザー情報をJOIN

        reaction_id_param = params[:reaction_id]

        # reaction_idが指定されていれば、そのリアクションで絞り込み
        if reaction_id_param.present?
          scope = scope.joins(:post_reactions)
                       .where(post_reactions: { reaction_id: reaction_id_param })
        else
          # 指定がなければ、全てのリアクションを対象に集計
          scope = scope.left_joins(:post_reactions)
        end

        # topic_idでの絞り込み（もしあれば）
        # scope = scope.where(topic_id: params[:topic_id]) if params[:topic_id].present?

        score_calculation = if reaction_id_param.present?
          # reaction_idが指定されている場合、そのIDのリアクション数だけをカウント
          "SUM(CASE WHEN post_reactions.reaction_id = #{reaction_id_param.to_i} THEN 1 ELSE 0 END)"
        else
          # 指定がなければ、全てのリアクション数をカウント
          "COUNT(post_reactions.id)"
        end

        # リアクション数(score)で集計・並び替え
        rankings = scope
          .select("posts.*, #{score_calculation} AS score")
          .group('posts.id', 'users.id')
          .order('score DESC')
          .limit(limit)

        # N+1問題を避けるために、必要なデータを事前に取得
        post_ids = rankings.map(&:id)
        posts_with_associations = Post.where(id: post_ids)
                                     .includes(:user, :post_reactions)
                                     .index_by(&:id)

        # 順序を保持しながらserialize_postを実行
        serialized_posts = rankings.map do |ranking_post|
          full_post = posts_with_associations[ranking_post.id]
          serialize_post(full_post)
        end

        render json: serialized_posts
      end

      # strong parameters
      def ranking_params
        params.fetch(:ranking, {}).permit(:topic_id, :reaction_id, :limit)
      end

      # limitパラメータを安全に取得・整形するメソッド
      def extract_limit(raw_limit)
        value = raw_limit.present? ? raw_limit.to_i : 10
        value.clamp(1, 100) # 1〜100の範囲に収める
      end

      # 全データに対して画像URLとリアクション数を追加するためのヘルパーメソッド
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

      def resolve_user_icon_url(user)
        return nil unless user

        url = user.icon_image_url
        return nil if url.blank?

        url.start_with?('http://', 'https://') ? url : build_image_url(url)
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
    end
  end
end