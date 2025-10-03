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
    end
  end
end
