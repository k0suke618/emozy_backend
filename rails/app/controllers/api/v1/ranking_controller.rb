module Api
  module V1
    class RankingController < ApplicationController
      include ImageUrlHelper
      protect_from_forgery with: :null_session

      # GET /api/v1/ranking
      def index
        # リアクション数の多い順に投稿を取得
        limit = extract_limit(params[:limit])

        rankings = Post.joins(:user)
                       .left_joins(:post_reactions)
                       .select('posts.*, users.name AS ranking_user_name, users.id AS ranking_user_id, COUNT(post_reactions.id) AS score')
                       .group('posts.id', 'users.id', 'users.name')
                       .order('score DESC')
                       .limit(limit)

        render json: build_ranking_payload(rankings)
      end

      # POST /api/v1/ranking
      # 受け取り例:
      # {
      #   "ranking": {
      #     "topic_id": 1,
      #     "reaction_id": 2,
      #     "limit": 10
      #   }
      # }
      def create
        # topic_id, reaction_idで絞り込み、リアクション数の多い順に投稿を取得
        permitted = ranking_params

        topic_id    = permitted[:topic_id]
        reaction_id = permitted[:reaction_id]
        limit       = extract_limit(permitted[:limit] || permitted[:count])

        scope = Post.joins(:user)
        
        # reaction_idが指定されていれば絞り込み、なければ全ての投稿を対象にする
        if reaction_id.present?
          scope = scope.joins(:post_reactions)
                       .where(post_reactions: { reaction_id: reaction_id })
        else
          scope = scope.left_joins(:post_reactions)
        end

        # topic_idが指定されていれば絞り込み、なければ全ての投稿を対象にする
        scope = scope.where(topic_id: topic_id) if topic_id.present?
        
        # リアクション数の多い順に投稿を取得
        rankings = scope
                   .select('posts.*, users.name AS ranking_user_name, users.id AS ranking_user_id, COUNT(post_reactions.id) AS score')
                   .group('posts.id', 'users.id', 'users.name')
                   .order('score DESC')
                   .limit(limit)

        render json: build_ranking_payload(rankings)
      end

      private

      def ranking_params
        if params.key?(:ranking)
          params.require(:ranking).permit(:topic_id, :reaction_id, :limit, :count)
        elsif params.key?(:post)
          params.require(:post).permit(:topic_id, :reaction_id, :limit, :count)
        else
          params.permit(:topic_id, :reaction_id, :limit, :count)
        end
      end

      def build_ranking_payload(posts)
        # 投稿のランキング情報を整形
        # 返す情報：
        # - rank: 順位 (1から始まる連番)
        # - post_id: 投稿ID
        # - post_content: 投稿内容
        # - post_image: 投稿画像URL
        # - user_id: 投稿者のユーザーID
        # - user_name: 投稿者のユーザー名
        # - score: 投稿のスコア（リアクション数）
        # - posts: 投稿オブジェクトの配列

        posts.each_with_index.map do |post, index|
          user_name = post['ranking_user_name'] || post.user&.name
          user_id   = post['ranking_user_id'] || post.user_id
          score     = post['score'] || 0
          # scoreは各投稿のリアクションの種類の数を引くようにする（0でなければ）
          if score > 0
            score -= post.post_reactions.select(:reaction_id).distinct.count if post.respond_to?(:post_reactions)
          end

          {
            rank: index + 1,
            post_id: post.id,
            post_content: post.content,
            post_image: build_image_url(post.image), # 画像URLに変換
            user_id: user_id,
            user_name: user_name,
            score: score.to_i
          }
        end
      end

      def extract_limit(raw_limit)
        value = raw_limit.present? ? raw_limit.to_i : 10
        value.clamp(1, 100)
      end
    end
  end
end
