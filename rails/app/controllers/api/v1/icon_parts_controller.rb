module Api
  module V1
    class IconPartsController < ApplicationController
      # アイコンパーツの取得
      def index
        icon_parts = IconPart.all.group_by(&:part_type)
        render json: icon_parts, status: :ok
      end
    end
  end
end