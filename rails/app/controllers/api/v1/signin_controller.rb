module Api
  module V1
    class SigninController < ApplicationController
      protect_from_forgery with: :null_session

      # POST /api/v1/signin
      def create
        # サインイン処理
        # emailとpasswordを受け取り、認証を行う
        # json
        # {
        #   "signin": {
        #     "email": "user@example.com",
        #     "password": "password"
        #   }
        # }
        permitted = signin_params
        user = User.find_by(email: permitted[:email])
        if user&.authenticate(permitted[:password])
          # 認証成功
          render json: user, status: :ok
        else
          # 認証失敗
          render json: { status: 'error', message: 'Invalid email or password' }, status: :unauthorized
        end
      end

      private
      def signin_params
        params.require(:signin).permit(:email, :password)
      end
    end
  end
end
