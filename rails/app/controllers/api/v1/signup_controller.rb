module Api
  module V1
    class SignupController < ApplicationController
      protect_from_forgery with: :null_session

      # POST /api/v1/sign_up
      def create
        # サインアップ処理
        # nameとemailとpasswordを受け取り、新規ユーザーを作成する
        permitted = signup_params
        user = User.new(permitted)
        user.point = 100
        if user.save
          # サインアップ成功
          # 作成したユーザー情報を返す
          render json: user, status: :created
        else
          # サインアップ失敗
          render json: { status: 'error', message: user.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end

      private

      def signup_params
        params.require(:signup).permit(:email, :password)
      end
    end
  end
end
