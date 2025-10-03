module Api
  module V1
    class BackgroundListController < ApplicationController
      protect_from_forgery with: :null_session
      include ImageUrlHelper

      def index
        background_lists = BackgroundList.all
        render json: { background_lists: background_lists }, status: :ok
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end

      def show
        # user idで絞り込んで取得
        user_id = params[:id]
        if user_id
          background_lists = BackgroundList.where(user_id: user_id)
          render json: { background_lists: background_lists }, status: :ok
        else
          render json: { error: 'user_id parameter is required' }, status: :bad_request
        end
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end
    end
  end
end
