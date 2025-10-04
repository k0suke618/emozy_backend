module Api
  module V1
    class BackgroundImageController < ApplicationController
      protect_from_forgery with: :null_session
      include ImageUrlHelper

      def update_db
        removed = purge_missing_background_images

        dir = Rails.root.join('public', 'assets', 'icon_maker', 'background')
        unless Dir.exist?(dir)
          render json: { error: 'Background image directory not found', removed: removed }, status: :not_found
          return
        end

        image_files = Dir.children(dir).select { |f| f.match?(/\.(png|jpg|jpeg|gif)$/i) }

        created = []
        updated = []

        image_files.each do |filename|
          relative_path = File.join('public', 'assets', 'icon_maker', 'background', filename)
          db_path = File.join('rails', relative_path)

          existing = BackgroundImage.find_by(image: db_path)
          if existing
            if existing.point != 50
              existing.update!(point: 50)
              updated << db_path
            end
            next
          end

          legacy_path = File.join('assets', 'icon_maker', 'background', filename)
          legacy_record = BackgroundImage.find_by(image: legacy_path)

          if legacy_record
            legacy_record.update!(image: db_path, point: 50)
            updated << db_path
          else
            BackgroundImage.create!(image: db_path, point: 50)
            created << db_path
          end
        end

        render json: {
          created: created,
          updated: updated,
          removed: removed,
          total_background_images: BackgroundImage.count
        }, status: :ok
      end

      # put /api/v1/background_image/:id
      def update
        background_image = BackgroundImage.find(params[:id])
        if background_image.update(background_image_params)
          render json: { background_image: background_image }, status: :ok
        else
          render json: { error: background_image.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def index
        background_images = BackgroundImage.all
        render json: { background_images: background_images }, status: :ok
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def background_image_params
        params.require(:background_image).permit(:image, :point)
      end

      def purge_missing_background_images
        removed = []
        BackgroundImage.find_each do |background_image|
          absolute_path = resolve_background_image_absolute_path(background_image.image)
          next if absolute_path && File.exist?(absolute_path)

          BackgroundImage.transaction do
            User.where(background_id: background_image.id).update_all(background_id: nil)
            background_image.destroy!
          end
          removed << background_image.image
        end
        removed
      end

      def resolve_background_image_absolute_path(path)
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
    end
  end
end
