module Api
  module V1
    class FavoritesController < ApplicationController
      protect_from_forgery with: :null_session

      def index
        favorites = Favorite.all
        render json: favorites, status: :ok
      end

      # GET /api/v1/favorites/:id（idはユーザーID）
      def show
        user_id = params[:id]
        # user_idで絞り込んで、お気に入りの投稿ID一覧を取得
        favorite_post_ids = Favorite.where(user_id: user_id).pluck(:post_id)

        render json: { favorite_post_ids: favorite_post_ids }, status: :ok
      end

      # POST /api/v1/favorites
      def create
        # json
        # {
        #   "favorite": {
        #     "user_id": 1,
        #     "post_id": 2
        #   }
        # }
        params_with_topic = favorite_params.to_h
        params_with_topic[:topic_id] = get_topic_id(params_with_topic[:post_id])
        favorite = Favorite.new(params_with_topic)
        if favorite.save
          render json: { message: "Favorite created successfully" }, status: :created
        else
          render json: { errors: favorite.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private
      def favorite_params
        params.require(:favorite).permit(:user_id, :post_id)
      end

      def get_topic_id(post_id)
        post = Post.find_by(id: post_id)
        post ? post.topic_id : nil
      end
    end
  end
end
