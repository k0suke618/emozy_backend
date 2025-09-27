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
      def create
        post = Post.new(post_params)
        if post.save
          render json: post, status: :created
        else
          render json: post.errors, status: :unprocessable_entity
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

      # フロント用にurlを追加
      def build_image_url(path)
        return nil if path.nil? # 画像がない場合はnilを返す
        return path if path.start_with?('http://', 'https://') # すでにURL形式の場合はそのまま返す
        "#{request.base_url}/#{path}" # 相対パスを絶対URLに変換（http://localhost:3000/assets/images/posts_image/???.jpeg）
      end
      
      # 全データに対して画像URLを追加するためのヘルパーメソッド
      def serialize_post(p)
        {
          id:         p.id,
          user_id:    p.user_id,
          topic_id:   p.topic_id,
          content:    p.content,
          image_url:  build_image_url(p.image), # 画像のURLを追加
          created_at: p.created_at,
          updated_at: p.updated_at
        }
      end
    end
  end
end