module Api
  module V1
    class UsersController < ApplicationController
      protect_from_forgery with: :null_session
      include ImageUrlHelper

      # GET /api/v1/users/:id
      def show
        user = User.find(params[:id])
        # render json: user
        render json: serialize_user(user)
      end

      # PATCH /api/v1/users/:id
      def update
        user = User.find(params[:id])
        if user.update(user_params)
          render json: { status: 'ok' }
        else
          render json: { status: 'error', message: user.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end

      private
      def user_params
        params.require(:user).permit(:email, :password)
      end

      # TODO: あとで、画像URLを追加する
      def serialize_user(user)
        user.as_json().merge(
          icon_image_url: "",
          background_image_url: "",
          frame_image_url: ""
        )
      end
    end
  end
end