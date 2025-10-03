module Api
  module V1
    class IconImageListController < ApplicationController
      protect_from_forgery with: :null_session

      def index
        icon_image_lists = IconImageList.all
        render json: { icon_image_lists: icon_image_lists.as_json }, status: :ok
      end

      def show
        user_id = params[:user_id]
        if user_id
          icon_image_lists = IconImageList.includes(:icon_image).where(user_id: user_id)
          render json: { icon_image_lists: icon_image_lists.as_json(include: :icon_image) }, status: :ok
        else
          render json: { error: 'user_id parameter is required' }, status: :bad_request
        end
      end
    end
  end
end