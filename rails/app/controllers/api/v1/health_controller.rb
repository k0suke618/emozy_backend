# app/controllers/api/v1/health_controller.rb
module Api
  module V1
    class HealthController < ApplicationController
      protect_from_forgery with: :null_session
      def ping
        render json: { ok: true }
      end
    end
  end
end
