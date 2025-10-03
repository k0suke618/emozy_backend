module Api
  module V1
    class IconPartsController < ApplicationController
      # アイコンパーツの取得
      def index
        icon_parts = IconPart.includes(:icon_parts_type)
        grouped_parts = icon_parts.group_by { |part| part.icon_parts_type&.content }

        render json: {
          icon_parts: grouped_parts.transform_values { |parts| parts.map { |part| part.as_json } }
        }, status: :ok
      end
    end
  end
end
