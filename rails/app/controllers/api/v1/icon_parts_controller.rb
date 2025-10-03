module Api
  module V1
    class IconPartsController < ApplicationController
      include IconAssetsPresenter
      # アイコンパーツの取得
      # http://localhost:3333/api/v1/icon_parts?user_id=12
      def index
        user = find_user(params[:user_id]) if params[:user_id].present?
        if params[:user_id].present? && user.nil?
          render json: { error: 'User not found' }, status: :bad_request
          return
        end

        render json: build_icon_assets_payload(user), status: :ok
      end

      private

      def find_user(user_id)
        User.find_by(id: user_id)
      end
    end
  end
end
