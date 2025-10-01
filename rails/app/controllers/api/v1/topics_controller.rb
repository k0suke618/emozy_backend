module Api
  module V1
    class TopicsController < ApplicationController
      protect_from_forgery with: :null_session
      # GET /api/v1/topics
      def index
        topics = Topic.all
        render_json(topics)
      end

      private
      def render_json(data, status: :ok)
        render json: data, status: status
      end
    end
  end
end