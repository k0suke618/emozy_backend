module Api
  module V1
    class PostsController < ApplicationController
      include ImageUrlHelper
      protect_from_forgery with: :null_session

      # GET /api/v1/posts
      def index
        posts = Post.order(created_at: :desc)
        render json: posts.map { |p| serialize_post(p) }
      end

      # POST /api/v1/posts
      # 受け取るパラメータ例
      # {
      #   "post": {
      #     "user_id": 1,
      #     "topic_id": 2,
      #     "content": "This is a new post",
      #     "image": base64_encoded_image_string,
      #     "reaction_ids": [1, 2, 3] # 追加するリアクションのID配列, reaction_idsはPost_Reactionsテーブルに対応（1個ずつ追加）
      #   }
      # }
      def create
        permitted_params = post_create_params
        reaction_ids = permitted_params.delete(:reaction_ids)
        image_base64 = permitted_params.delete(:image)

        post = Post.new(permitted_params)

        begin
          Post.transaction do
            # reaction_idsが指定されている場合は対応するis_set_reaction_nをtrueに設定
            if reaction_ids.present?
              post.is_set_reaction_1 = false # デフォルトでtrueになっているのでfalseにリセット
              reaction_ids.each do |reaction_id|
                reaction_number = Integer(reaction_id, exception: false)
                next unless reaction_number&.between?(1, 12)

                post.send("is_set_reaction_#{reaction_number}=", true)
              end
            end

            # 画像がbase64エンコードされている場合はデコードして保存
            post.image = save_base64_image(image_base64) if image_base64.present?

            post.save!
          end

          render json: post, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render json: e.record.errors, status: :unprocessable_entity
        end
      end

      # GET /api/v1/posts/:id
      def show
        post = Post.find(params[:id])
        render json: serialize_post(post)
      end

      # PUT /api/v1/posts/:id
      def update
        # 例: { "post": {"user_id": 1, "reaction_id": 1, "increment": true } }
        # incrementがtrueなら+1、falseなら-1
        permitted_params = post_update_params
        post = Post.find(params[:id])

        reaction_id = permitted_params[:reaction_id]
        return render json: { error: 'reaction_id is required' }, status: :unprocessable_entity if reaction_id.nil?
        reaction_id = reaction_id.to_i

        user_id = permitted_params[:user_id]
        return render json: { error: 'user_id is required' }, status: :unprocessable_entity if user_id.nil?

        return render json: { error: 'increment parameter is required' }, status: :unprocessable_entity unless permitted_params.key?(:increment)

        increment_flag = ActiveModel::Type::Boolean.new.cast(permitted_params[:increment])

        if increment_flag
          # リアクションを＋1するように、Post_Reactionsテーブルにレコードを追加
          reaction = post.post_reactions.find_or_initialize_by(reaction_id: reaction_id, user_id: user_id)

          if reaction.persisted?
            # すでに同じユーザーが同じリアクションをしている場合はエラー
            reaction.errors.add(:user_id, 'has already reacted with this reaction')
            raise ActiveRecord::RecordInvalid.new(reaction)
          else
            reaction.save!
          end
        else
          # リアクションを－1するように、Post_Reactionsテーブルからレコードを削除
          reaction = post.post_reactions.find_by(reaction_id: reaction_id, user_id: user_id)

          unless reaction
            return render json: { error: 'reaction not found for user' }, status: :not_found
          end

          reaction.destroy!
        end
        
        # 変更後の投稿データを返す
        render json: serialize_post(post.reload)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Post not found" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: e.record.errors, status: :unprocessable_entity
      end

      # DELETE /api/v1/posts/:id
      def destroy
        post = Post.find(params[:id])
        post.destroy
        head :no_content
      end

      private

      def post_params
        params.require(:post).permit(:user_id, :topic_id, :content, :image)
      end

      def post_create_params
        params.require(:post).permit(:user_id, :topic_id, :content, :image, reaction_ids: [])
      end

      def post_update_params
        params.require(:post).permit(:user_id, :reaction_id, :increment)
      end
      
      # 全データに対して画像URLとリアクション数を追加するためのヘルパーメソッド
      def serialize_post(p)
        {
          id:         p.id,
          user_id:    p.user_id,
          topic_id:   p.topic_id,
          content:    p.content,
          image_url:  build_image_url(p.image), # 画像のURLを追加
          num_reactions: get_num_reactions(p), # リアクション数を追加
          created_at: p.created_at,
          updated_at: p.updated_at
        }
      end

      # base64エンコードされた画像をデコードして保存するメソッド
      def save_base64_image(base64_image)
        return nil if base64_image.nil?

        data_segment = base64_image.to_s.split(',', 2).last

        begin
          image_data = Base64.decode64(data_segment)
        rescue ArgumentError => e
          invalid_post = Post.new
          invalid_post.errors.add(:image, 'is not valid base64 data')
          raise ActiveRecord::RecordInvalid.new(invalid_post), cause: e
        end

        extension = detect_image_extension(image_data)
        unless extension
          invalid_post = Post.new
          invalid_post.errors.add(:image, 'format is not supported')
          raise ActiveRecord::RecordInvalid.new(invalid_post)
        end

        filename = "post_#{Time.now.to_i}.#{extension}"
        dir_path = Rails.root.join('public', 'assets', 'posts', 'images')
        FileUtils.mkdir_p(dir_path) unless Dir.exist?(dir_path)
        file_path = dir_path.join(filename)

        File.open(file_path, 'wb') do |f|
          f.write(image_data)
        end

        "assets/posts/images/#{filename}"
      end

      def detect_image_extension(image_data)
        return 'png' if image_data.start_with?("\x89PNG".b)
        return 'jpg' if image_data.start_with?("\xFF\xD8\xFF".b)
        return 'gif' if image_data.start_with?('GIF8')

        nil
      end

      # 投稿に紐づくリアクション数を取得するメソッド
      def get_num_reactions(post)
        # リアクションの種類ごとにカウントする
        # fix: 投稿者分もカウントされるから、-1する
        # post.post_reactions.group(:reaction_id).count.transform_values { |v| v - 1 }

        # is_set_reaction_nがtrueのものだけカウントする場合
        counts = {}
        (1..12).each do |i|
          if post.send("is_set_reaction_#{i}")
            counts[i] = post.post_reactions.where(reaction_id: i).count
          end
        end
        counts
      end
    end
  end
end
