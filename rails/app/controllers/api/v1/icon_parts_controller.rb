module Api
  module V1
    class IconPartsController < ApplicationController
      # アイコンパーツの取得
      # http://localhost:3333/api/v1/icon_parts?user_id=12
      def index
        user = find_user(params[:user_id]) if params[:user_id].present?
        if params[:user_id].present? && user.nil?
          render json: { error: 'User not found' }, status: :bad_request
          return
        end

        icon_parts = IconPart.includes(:icon_parts_type)
        grouped_parts = icon_parts.group_by { |part| part.icon_parts_type&.content }

        background_images = BackgroundImage.all
        frame_images = FrameImage.all

        owned_background_ids = user ? user.background_lists.pluck(:image_id) : []
        owned_frame_ids = user ? user.frame_lists.pluck(:image_id) : []

        render json: {
          icon_parts: grouped_parts.transform_values { |parts| parts.map(&:as_json) },
          background_images: background_images.map { |image| serialize_with_owned(image, owned_background_ids.include?(image.id)) },
          frame_images: frame_images.map { |image| serialize_with_owned(image, owned_frame_ids.include?(image.id)) }
        }, status: :ok
      end

      private

      def serialize_with_owned(image_record, owned)
        image_record.as_json.merge('owned' => owned)
      end

      def find_user(user_id)
        User.find_by(id: user_id)
      end
    end
  end
end
