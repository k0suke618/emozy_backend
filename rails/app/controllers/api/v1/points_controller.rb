module Api
  module V1
    class PointsController < ApplicationController
      skip_before_action :verify_authenticity_token
      def index
        points = Point.all
        render json: points
      end

      def update
        # {
          # "point": {
          # "user_id": 1, 
          # "value": 10000, 
          # "content": "獲得内容の説明" 
          # }
        # }
        # is_getがtrueならポイントをvalue増やす、falseなら減らす

        # user_idからユーザーを特定
        user = User.find(point_params[:user_id])
        # Point_types DBに登録
        # columns: content
        # contentはポイント獲得・消費の理由を記載
        point_type = PointType.find_or_create_by(content: point_params[:content])
        # Points DBに登録
        point = Point.find_or_create_by(value: point_params[:value])

        if user && point_type && point
          # usersテーブルのポイントを更新
          user.point += point.value
          user.save
        
        # 更新したユーザー情報をレスポンスに含める
        render json: { status: 'SUCCESS', message: 'ポイント更新成功', data: user }, status: :ok
        else
          render json: { status: 'ERROR', message: 'ポイント更新失敗', data: {} }, status: :unprocessable_entity
        end
        
      end

      private
      def point_params
        params.require(:point).permit(:user_id, :value, :content)
      end
    end
  end
end
