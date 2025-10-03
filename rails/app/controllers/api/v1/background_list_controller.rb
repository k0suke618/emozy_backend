module Api
  module V1
    class BackgroundListController < ApplicationController
      protect_from_forgery with: :null_session
      include ImageUrlHelper
      include IconAssetsPresenter

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
      def acquire
        user_id = acquire_params[:user_id]
        background_id = acquire_params[:background_image_id]

        user = find_user(user_id)
        unless user
          render json: { error: 'User not found' }, status: :bad_request
          return
        end

        background_image = BackgroundImage.find_by(id: background_id)
        unless background_image
          render json: { error: 'Background image not found' }, status: :bad_request
          return
        end

        if user.background_lists.exists?(image_id: background_image.id)
          render json: { error: 'Background already owned' }, status: :bad_request
          return
        end

        if user.point < background_image.point.to_i
          render json: { error: 'Insufficient points' }, status: :unprocessable_entity
          return
        end

        ActiveRecord::Base.transaction do
          user.background_lists.create!(image: background_image)
          user.update!(point: user.point - background_image.point.to_i)
        end

        render json: build_icon_assets_payload(user), status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def acquire_params
        params.permit(:user_id, :background_image_id)
      end

      def find_user(user_id)
        User.find_by(id: user_id)
      end
    end
  end
end
