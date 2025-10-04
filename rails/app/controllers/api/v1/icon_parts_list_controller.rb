module Api
  module V1
    class IconPartsListController < ApplicationController
      protect_from_forgery with: :null_session

      def index
        icon_parts = IconPartsList.all
        render json: { icon_parts: icon_parts }, status: :ok
      end
      # get /api/v1/icon_parts_list?user_id=1
      def show
        user_id = params[:user_id]
        if user_id.nil?
          render json: { error: 'user_id is required' }, status: :bad_request
          return
        end

        icon_parts_list = IconPartsList.find_by(user_id: user_id)
        if icon_parts_list
          render json: { icon_parts_list: icon_parts_list }, status: :ok
        else
          render json: { error: 'Icon parts list not found' }, status: :not_found
        end
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end
    end
  end
end