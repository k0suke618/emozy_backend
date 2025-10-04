module Api
  module V1
    class IconPartsTypeController < ApplicationController
      # アイコンパーツの取得
      def index
        icon_parts = IconPartsType.all
        render json: icon_parts, status: :ok
      end
    end
  end
end