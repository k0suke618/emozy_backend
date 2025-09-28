module Api
  module V1
    class PostReactionsController < ApplicationController
      protect_from_forgery with: :null_session

      # GET /api/v1/post_reactions
      def index
        post_reactions = PostReaction.all
        render json: post_reactions
      end

      # GET /api/v1/post_reactions/:id
      def show
        post_reaction = PostReaction.find(params[:id])
        render json: post_reaction
      end

      # POST /api/v1/post_reactions
      def create
        post_reaction = PostReaction.new(post_reaction_params)
        if post_reaction.save
          render json: post_reaction, status: :created
        else
          render json: post_reaction.errors, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/post_reactions/:id
      def destroy
        post_reaction = PostReaction.find(params[:id])
        post_reaction.destroy
        head :no_content
      end

      private

      def post_reaction_params
        params.require(:post_reaction).permit(:post_id, :user_id, :reaction_id, :count)
      end

      def post_reaction_update_params
        params.require(:post_reaction).permit(:reaction_id, :increment)
      end
    end
  end
end
