module Api
  module V1
    class IconMakerController < ApplicationController
      # アイコンメーカーのデータ更新（ファイルの中身をDBに追加）
      def data_update
        base_dir = icon_maker_base_dir
        icon_parts_dir = fetch_subfolders(base_dir)

        icon_parts_dir.each do |type_folder|
          type_name = File.basename(type_folder)
          icon_parts_type = find_or_create_icon_parts_type(type_name)
          next unless icon_parts_type

          image_paths = fetch_image_paths(type_folder)
          image_paths.each do |image_path|
            filename = File.basename(image_path)

            IconPart.find_or_create_by!(
              image: filename,
              icon_parts_type: icon_parts_type,
            )
          end
        end

        @icon_parts = IconPart.includes(:icon_parts_type)
        render json: { icon_parts: @icon_parts }, status: :ok
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      # アイコンメーカーのベースフォルダを判定
      def icon_maker_base_dir
        %w[public/assets/icon_maker app/assets/images/icon_maker].each do |relative_path|
          candidate = Rails.root.join(*relative_path.split('/'))
          return candidate if Dir.exist?(candidate)
        end

        raise StandardError, 'アイコンパーツのディレクトリが見つかりませんでした'
      end

      # 指定したフォルダの画像ファイルのパスを配列で取得
      def fetch_image_paths(folder_path)
        Dir.glob("#{folder_path}/*").filter_map do |file|
          file if File.file?(file) && %w(.png .jpg .jpeg .gif).include?(File.extname(file).downcase)
        end
      end

      # フォルダ内のサブフォルダを取得
      def fetch_subfolders(folder_path)
        Dir.glob("#{folder_path}/*").select { |entry| File.directory?(entry) }
      end

      # ディレクトリ名からアイコンパーツ種別を取得・作成
      def find_or_create_icon_parts_type(type_name)
        normalized_name = type_name.to_s.strip
        return if normalized_name.empty?

        IconPartsType.find_or_create_by!(content: normalized_name)
      end
    end
  end
end
