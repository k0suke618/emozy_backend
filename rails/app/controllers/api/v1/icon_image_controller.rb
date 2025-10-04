module Api
  module V1
    class IconImageController < ApplicationController
      protect_from_forgery with: :null_session
      include ImageUrlHelper

      # アイコン画像ディレクトリとDBの差分を同期するエンドポイント
      def update_db
        removed = purge_missing_icon_images

        dir = Rails.root.join('public', 'assets', 'icons')
        unless Dir.exist?(dir)
          render json: { error: 'Icon image directory not found', removed: removed }, status: :not_found
          return
        end

        image_files = Dir.children(dir).select { |f| f.match?(/\.(png|jpg|jpeg|gif)$/i) }

        created = []
        updated = []

        image_files.each do |filename|
          relative_path = File.join('public', 'assets', 'icons', filename)
          db_path = File.join('rails', relative_path)

          existing = IconImage.find_by(image: db_path)
          if existing
            if existing.point != 50
              existing.update!(point: 50)
              updated << db_path
            end
            next
          end

          legacy_path = File.join('assets', 'icons', filename)
          legacy_record = IconImage.find_by(image: legacy_path)

          if legacy_record
            legacy_record.update!(image: db_path, point: 50)
            updated << db_path
          else
            IconImage.create!(image: db_path, point: 50)
            created << db_path
          end
        end

        render json: {
          created: created,
          updated: updated,
          removed: removed,
          total_icon_images: IconImage.count
        }, status: :ok
      end

      # アイコン画像の属性を更新
      def update
        icon_image = IconImage.find(params[:id])
        if icon_image.update(icon_image_params)
          render json: { icon_image: icon_image }, status: :ok
        else
          render json: { error: icon_image.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # 登録済みのアイコン画像一覧を返却
      def index
        if params[:user_id].present?
          render_user_icon_images
          return
        end

        icon_images = IconImage.where("image LIKE ?", 'rails/public/assets/icons/%')
        render json: { icon_images: icon_images.map { |image| serialize_icon_image(image) } }, status: :ok
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def render_user_icon_images
        user = User.find_by(id: params[:user_id])
        unless user
          render json: { error: 'User not found' }, status: :bad_request
          return
        end

        icon_image_lists = user.icon_image_lists.includes(:image)

        generated_entries = icon_image_lists.select { |entry| generated_icon?(entry.image) }
        standard_entries = icon_image_lists - generated_entries

        stock_icons = IconImage.where("image LIKE ?", 'rails/public/assets/icons/%')
        owned_icon_ids = standard_entries.map { |entry| entry.image_id }.compact
        unowned_icons = stock_icons.reject { |icon| owned_icon_ids.include?(icon.id) }

        render json: {
          owned_icon_images: standard_entries.map { |entry| serialize_icon_image_list(entry) }.compact,
          unowned_icon_images: unowned_icons.map { |icon| serialize_icon_image(icon) },
          generated_icon_images: generated_entries.map { |entry| serialize_icon_image_list(entry) }.compact
        }, status: :ok
      end

      def serialize_icon_image_list(entry)
        icon_image = entry.image
        return nil unless icon_image

        serialize_icon_image(icon_image).merge('icon_image_list_id' => entry.id)
      end

      def serialize_icon_image(icon_image)
        data = icon_image.as_json
        data['image_url'] = build_image_url(icon_image.image)
        data
      end

      def generated_icon?(icon_image)
        path = icon_image&.image.to_s
        path.start_with?('assets/generated_icons/') || path.start_with?('rails/public/assets/generated_icons/')
      end

      def icon_image_params
        params.require(:icon_image).permit(:image, :point)
      end

      # 実ファイルが消えているレコードを整理し、関連情報をクリーンアップ
      def purge_missing_icon_images
        removed = []
        IconImage.find_each do |icon_image|
          absolute_path = resolve_icon_image_absolute_path(icon_image.image)
          next if absolute_path && File.exist?(absolute_path)

          IconImage.transaction do
            UserIcon.where(icon_image_id: icon_image.id).destroy_all
            clear_icon_image_urls(icon_image)
            icon_image.destroy!
          end
          removed << icon_image.image
        end
        removed
      end

      # icon_image.image に保存されている形式の違いを吸収して絶対パスを解決
      def resolve_icon_image_absolute_path(path)
        return nil if path.blank? || path.match?(%r{^https?://})

        normalized =
          if path.start_with?('rails/')
            path.sub(/^rails\//, '')
          elsif path.start_with?('public/')
            path
          elsif path.start_with?('/')
            File.join('public', path.delete_prefix('/'))
          elsif path.start_with?('assets/')
            File.join('public', path)
          else
            path
          end

        Rails.root.join(normalized)
      end

      # User#icon_image_url に保存された各種表記揺れをまとめてクリア
      def clear_icon_image_urls(icon_image)
        return if icon_image.image.blank?

        variants = [icon_image.image]

        without_rails = icon_image.image.sub(/^rails\//, '')
        variants << without_rails unless without_rails == icon_image.image

        stripped = without_rails.sub(%r{^/+}, '')
        variants << stripped unless stripped == without_rails

        if stripped.start_with?('public/')
          variants << stripped.sub(/^public\//, '')
        end

        variants << "/#{stripped}"

        if defined?(request) && request
          variants << build_image_url(icon_image.image)
        end

        User.where(icon_image_url: variants.uniq).update_all(icon_image_url: '')
      end
    end
  end
end
