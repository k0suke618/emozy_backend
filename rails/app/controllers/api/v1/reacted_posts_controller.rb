module Api
  module V1
    class ReactedPostsController < ApplicationController
      protect_from_forgery with: :null_session

      # GET /api/v1/reacted_posts?user_id=1
      def index
        user_id = params[:user_id]
        if user_id.blank?
          render json: { error: 'user_id is required' }, status: :bad_request
          return
        end

        reacted_posts = PostReaction.where(user_id: user_id).map do |pr|
          { post_id: pr.post_id, reaction_id: pr.reaction_id }
        end

        render json: reacted_posts
      end
    end
  end
end