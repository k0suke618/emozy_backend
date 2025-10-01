module Api
  module V1
    class AccountController < ApplicationController
      protect_from_forgery with: :null_session
    
      # put /api/v1/make/:id
      def update
        # json
        # {
        #   "user": {
        #     "name": "new_name", # "自由（1文字以上）"
        #     "profile": "new_profile" # 自由（1文字以上）
        #   }
        # }
        # validation
        if account_params[:name] && !validate_name(account_params[:name])
          return render json: { error: "Invalid name format" }, status: :unprocessable_entity
        end
        if account_params[:profile] && !validate_profile(account_params[:profile])
          return render json: { error: "Invalid profile format" }, status: :unprocessable_entity
        end

        # idからuserをuserを検索
        user = User.find_by(id: params[:id])
        if user
          # ユーザー情報を更新
          if user.update(account_params.except(:email))
            # ユーザー情報を返す
            render json: { user: user }, status: :ok
          else
            render json: { error: user.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { error: "User not found" }, status: :not_found
        end
      end

      private
      def account_params
        params.require(:user).permit(:email, :name, :profile)
      end

      def validate_name(name)
        # 何かしらの文字列が入っていれば許可する
        name.is_a?(String) && !name.strip.empty?
      end

      def validate_profile(profile)
        # 何かしらの文字列が入っていれば許可する
        profile.is_a?(String) && !profile.strip.empty?
      end
    end
  end
end