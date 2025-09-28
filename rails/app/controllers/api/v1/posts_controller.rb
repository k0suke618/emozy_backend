module Api
  module V1
    class PostsController < ApplicationController
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
            post.image = save_base64_image(image_base64) if image_base64.present?
            raise ActiveRecord::RecordInvalid.new(post) unless post.save

            if reaction_ids.present?
              reaction_ids.each do |reaction_id|
                post.post_reactions.create!(reaction_id: reaction_id, user_id: post.user_id)
              end
            end
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
        post = Post.find(params[:id])
        if post.update(post_params)
          render json: post
        else
          render json: post.errors, status: :unprocessable_entity
        end
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

      # フロント用にurlを追加
      def build_image_url(path)
        return nil if path.nil? # 画像がない場合はnilを返す
        return path if path.start_with?('http://', 'https://') # すでにURL形式の場合はそのまま返す
        "#{request.base_url}/#{path}" # 相対パスを絶対URLに変換（http://localhost:3000/assets/images/posts_image/???.jpeg）
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
        post.post_reactions.group(:reaction_id).count
      end
    end
  end
end
