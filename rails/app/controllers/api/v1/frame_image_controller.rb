module Api
  module V1
    class FrameImageController < ApplicationController
      protect_from_forgery with: :null_session
      include ImageUrlHelper
      
      def update_db
        removed = purge_missing_frame_images

        dir = Rails.root.join('public', 'assets', 'icon_maker', 'frame')
        unless Dir.exist?(dir)
          render json: { error: 'Frame image directory not found', removed: removed }, status: :not_found
          return
        end

        image_files = Dir.children(dir).select { |f| f.match?(/\.(png|jpg|jpeg|gif)$/i) }

        created = []
        updated = []

        image_files.each do |filename|
          relative_path = File.join('public', 'assets', 'icon_maker', 'frame', filename)
          db_path = File.join('rails', relative_path)

          existing = FrameImage.find_by(image: db_path)
          if existing
            if existing.point != 50
              existing.update!(point: 50)
              updated << db_path
            end
            next
          end

          legacy_path = File.join('assets', 'icon_maker', 'frame', filename)
          legacy_record = FrameImage.find_by(image: legacy_path)

          if legacy_record
            legacy_record.update!(image: db_path, point: 50)
            updated << db_path
          else
            FrameImage.create!(image: db_path, point: 50)
            created << db_path
          end
        end

        render json: {
          created: created,
          updated: updated,
          removed: removed,
          total_frame_images: FrameImage.count
        }, status: :ok
      end

      # put /api/v1/frame_image/:id
      def update
        frame_image = FrameImage.find(params[:id])
        if frame_image.update(frame_image_params)
          render json: { frame_image: frame_image }, status: :ok
        else
          render json: { error: frame_image.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def index
        @frame_images = FrameImage.all
        render json: { frame_images: @frame_images }, status: :ok
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end

      # get /api/v1/frame_image/:id
      def get_image_url
        frame_image = FrameImage.find(params[:id])
        image_url = build_image_url(frame_image.image)
        render json: { image_url: image_url }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'FrameImage not found' }, status: :not_found
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def frame_image_params
        params.require(:frame_image).permit(:image, :point)
      end

      def purge_missing_frame_images
        removed = []
        FrameImage.find_each do |frame_image|
          absolute_path = resolve_frame_image_absolute_path(frame_image.image)
          next if absolute_path && File.exist?(absolute_path)

          FrameImage.transaction do
            User.where(frame_id: frame_image.id).update_all(frame_id: nil)
            frame_image.destroy!
          end
          removed << frame_image.image
        end
        removed
      end

      def resolve_frame_image_absolute_path(path)
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
