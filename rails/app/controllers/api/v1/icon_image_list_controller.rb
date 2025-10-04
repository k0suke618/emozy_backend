module Api
  module V1
    class IconImageListController < ApplicationController
      protect_from_forgery with: :null_session
      include IconAssetsPresenter

      # 全ユーザー分のアイコン保有リストを取得（管理用）
      def index
        icon_image_lists = IconImageList.includes(:image).all
        render json: { icon_image_lists: serialize_with_icon(icon_image_lists) }, status: :ok
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end

      # 指定ユーザーのアイコン保有状況を返却
      def show
        user_id = params[:id] || params[:user_id]
        if user_id
          icon_image_lists = IconImageList.includes(:image).where(user_id: user_id)
          render json: { icon_image_lists: serialize_with_icon(icon_image_lists) }, status: :ok
        else
          render json: { error: 'user_id parameter is required' }, status: :bad_request
        end
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end

      # ポイント消費でアイコン画像を取得するトランザクション
      def acquire
        user_id = acquire_params[:user_id]
        icon_image_id = acquire_params[:icon_image_id]

        user = find_user(user_id)
        unless user
          render json: { error: 'User not found' }, status: :bad_request
          return
        end

        icon_image = IconImage.find_by(id: icon_image_id)
        unless icon_image
          render json: { error: 'Icon image not found' }, status: :bad_request
          return
        end

        if user.icon_image_lists.exists?(image_id: icon_image.id)
          render json: { error: 'Icon image already owned' }, status: :bad_request
          return
        end

        required_point = icon_image.point || 0
        if user.point < required_point
          render json: { error: 'Insufficient points' }, status: :unprocessable_entity
          return
        end

        ActiveRecord::Base.transaction do
          user.icon_image_lists.create!(image: icon_image)
          user.update!(point: user.point - required_point)
        end

        render json: build_icon_assets_payload(user), status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def acquire_params
        params.permit(:user_id, :icon_image_id)
      end

      def find_user(user_id)
        User.find_by(id: user_id)
      end

      def serialize_with_icon(records)
        records.map do |record|
          record.as_json.merge('icon_image' => record.image&.as_json)
        end
      end
    end
  end
end
