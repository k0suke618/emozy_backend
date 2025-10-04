module Api
  module V1
    class FrameListController < ApplicationController
      protect_from_forgery with: :null_session
      include ImageUrlHelper
      include IconAssetsPresenter

      def index
        @frame_lists = FrameList.all
        render json: { frame_lists: @frame_lists }, status: :ok
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end

      def acquire
        user_id = acquire_params[:user_id]
        frame_image_id = acquire_params[:frame_image_id]

        user = find_user(user_id)
        unless user
          render json: { error: 'User not found' }, status: :bad_request
          return
        end

        frame_image = FrameImage.find_by(id: frame_image_id)
        unless frame_image
          render json: { error: 'Frame image not found' }, status: :bad_request
          return
        end

        if user.frame_lists.exists?(image_id: frame_image.id)
          render json: { error: 'Frame already owned' }, status: :bad_request
          return
        end

        if user.point < 50
          render json: { error: 'Insufficient points' }, status: :unprocessable_entity
          return
        end

        ActiveRecord::Base.transaction do
          user.frame_lists.create!(image: frame_image)
          user.update!(point: user.point - 50)
        end

        render json: build_icon_assets_payload(user), status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def acquire_params
        params.permit(:user_id, :frame_image_id)
      end

      def find_user(user_id)
        User.find_by(id: user_id)
      end
    end
  end
end
