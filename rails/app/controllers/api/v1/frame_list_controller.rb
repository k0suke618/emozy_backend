module Api
  module V1
    class FrameListsController < ApplicationController
      protect_from_forgery with: :null_session
      include ImageUrlHelper

      def index
        @frame_lists = FrameList.all
        render json: { frame_lists: @frame_lists }, status: :ok
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end
    end
  end
end