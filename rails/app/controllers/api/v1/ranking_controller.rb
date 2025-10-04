module Api
  module V1
    class RankingController < ApplicationController
      # CSRFトークン検証を無効化
      protect_from_forgery with: :null_session

      # GET /api/v1/ranking
      # 全体のランキングを取得
      def index
        @current_user_id = params[:user_id].presence&.to_i
        fetch_and_render_ranking
      end

      # POST /api/v1/ranking
      # 特定のリアクションでのランキングを取得
      def create
        @current_user_id = params[:user_id].presence&.to_i
        fetch_and_render_ranking(ranking_params)
      end

      private

      # ランキングデータを取得してJSONとして描画する共通メソッド
      def fetch_and_render_ranking(params = {})
        limit = extract_limit(params[:limit])
        scope = Post.joins(:user) # ユーザー情報をJOIN

        # reaction_idが指定されていれば、そのリアクションで絞り込み
        if params[:reaction_id].present?
          scope = scope.joins(:post_reactions)
                       .where(post_reactions: { reaction_id: params[:reaction_id] })
        else
          # 指定がなければ、全てのリアクションを対象に集計
          scope = scope.left_joins(:post_reactions)
        end

        # topic_idでの絞り込み（もしあれば）
        scope = scope.where(topic_id: params[:topic_id]) if params[:topic_id].present?

        # リアクション数(score)で集計・並び替え
        rankings = scope
          .select('posts.*, COUNT(post_reactions.id) AS score')
          .group('posts.id')
          .order('score DESC')
          .limit(limit)

        # homeページなどと共通の `serialize_post` を使ってJSONを生成
        render json: rankings.map { |p| serialize_post(p) }
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
    end
  end
end