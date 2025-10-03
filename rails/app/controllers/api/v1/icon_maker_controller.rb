module Api
  module V1
    class IconMakerController < ApplicationController
      protect_from_forgery with: :null_session
      include ImageUrlHelper

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
            # assets/icon_maker/skin/skin1.png のような相対パスに変換して保存
            filename = image_path.sub(%r{^#{Regexp.escape(base_dir.to_s)}/}, 'assets/icon_maker/')
            next if IconPart.exists?(image: filename, icon_parts_type: icon_parts_type)

            IconPart.create!(
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

      def index
        # アイコンパーツの一覧をtypeごとに取得して返す
        # key: アイコンパーツ種別のcontent, value: その種別のアイコンパーツ一覧
        icon_parts = IconPart.includes(:icon_parts_type).all
        grouped_parts = icon_parts.group_by { |part| part.icon_parts_type.content }
        render json: { icon_parts: grouped_parts }, status: :ok
      end

      def save
        # icon_parts_listテーブルにアイコンパーツを保存
        # postリクエストで受け取る
        # 例: {
        #   "user_id": 1,
        #   "icon_parts": {
        #       "skin": 10,
        #       "accessory": 2,
        #       "back_hair": 3,
        #       "clothing": 4,
        #       "eyebrows": 5,
        #       "eyes": 6,
        #       "front_hair": 7,
        #       "high_light": 8,
        #       "mouth": 9
        #     }
        # }
        
        icon_parts_data = params[:icon_parts].presence || params[:icon_parts_list]
        normalized_parts = normalize_icon_parts(icon_parts_data)
        if normalized_parts.blank?
          render json: { error: 'Invalid icon parts data' }, status: :bad_request
          return
        end

        fallback_user = find_user(params[:user_id]) if params[:user_id].present?
        if params[:user_id].present? && fallback_user.nil?
          render json: { error: 'User not found' }, status: :bad_request
          return
        end
        icon_parts_lists = []

        normalized_parts.each do |parts|
          typed_parts = parts.deep_symbolize_keys
          user = resolve_user_for_parts(typed_parts, fallback_user)
          unless user
            render json: { error: 'User not found' }, status: :bad_request
            return
          end

          icon_parts_list = IconPartsList.new(user: user)
          assign_icon_part_images(icon_parts_list, typed_parts)

          missing_columns = required_icon_part_columns.reject do |column|
            icon_parts_list.public_send(column).present?
          end

          if missing_columns.any?
            render json: { error: 'Invalid icon parts data', missing_columns: missing_columns }, status: :bad_request
            return
          end

          icon_parts_lists << icon_parts_list
        end

        IconPartsList.transaction { icon_parts_lists.each(&:save!) }

        render json: { message: 'Icon parts saved' }, status: :created
      end

      # get /api/v1/icon_maker?user_id=1
      def load
        # user_idに紐づくicon_parts_listを取得して返す
        user = find_user(params[:user_id])
        unless user
          render json: { error: 'User not found' }, status: :bad_request
          return
        end

        icon_parts_list = IconPartsList.find_by(user: user)
        if icon_parts_list
          render json: { icon_parts_list: icon_parts_list }, status: :ok
        else
          render json: { error: 'Icon parts list not found' }, status: :not_found
        end
      end

      # post /api/v1/icon_maker/make_icon
      def make_icon
      # 受け取ったパーツ情報を元にアイコン画像を生成して返す
      #   {
      #   "icon_parts":
      #     {
      #       "id": 1,
      #       "user_id": 1,
      #       "eyes_image": "assets/icon_maker/test.png",
      #       "mouth_image": "assets/icon_maker/test.png",
      #       "skin_image": "assets/icon_maker/test.png",
      #       "front_hair_image": "assets/icon_maker/test.png",
      #       "back_hair_image": "assets/icon_maker/test.png",
      #       "eyebrows_image": "assets/icon_maker/test.png",
      #       "high_light_image": "assets/icon_maker/test.png",
      #       "clothing_image": "assets/icon_maker/test.png",
      #       "accessory_image": "assets/icon_maker/test.png",
      #       "background": "assets/icon_maker/test.png",
      #       "frame": "assets/icon_maker/test.png"
      #   }
      # }
        layer_order = %w[background skin back_hair clothing eyebrows eyes high_light front_hair mouth accessory frame]
        icon_parts_data = params[:icon_parts].presence || params[:icon_parts_list]
        normalized_parts = normalize_icon_parts(icon_parts_data)
        if normalized_parts.blank?
          render json: { error: 'Invalid icon parts data' }, status: :bad_request
          return
        end

        fallback_user = find_user(params[:user_id]) if params[:user_id].present?

        requests = []
        normalized_parts.each do |parts|
          typed_parts = parts.deep_symbolize_keys
          layer_images = extract_layer_images(typed_parts)

          if layer_images.empty?
            render json: { error: 'No valid icon parts provided' }, status: :bad_request
            return
          end

          user = resolve_user_for_parts(typed_parts, fallback_user)
          if typed_parts.key?(:user_id) && user.nil?
            render json: { error: 'User not found' }, status: :bad_request
            return
          end

          requests << {
            user: user,
            layer_images: layer_images
          }
        end

        begin
          require 'mini_magick'
        rescue LoadError
          render json: { error: 'Image processing library not available' }, status: :internal_server_error
          return
        end

        generated_entries = []

        requests.each do |request|
          images = []
          layer_order.each do |layer|
            image_file = request[:layer_images][layer.to_sym]
            next unless image_file.present?

            image_path = absolute_image_path(image_file)
            unless image_path && File.exist?(image_path)
              render json: { error: "Image file not found: #{image_file}" }, status: :bad_request
              return
            end

            images << MiniMagick::Image.open(image_path.to_s)
          end

          if images.empty?
            render json: { error: 'No valid icon parts provided' }, status: :bad_request
            return
          end

          base_image = images.shift
          images.each do |img|
            base_image = base_image.composite(img) do |c|
              c.compose 'Over'
              c.geometry '+0+0'
            end
          end

          output_dir = Rails.root.join('public', 'assets', 'generated_icons')
          FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)
          output_filename = "icon_#{SecureRandom.uuid}.png"
          output_path = output_dir.join(output_filename)
          base_image.write(output_path)

          generated_entries << {
            path: "assets/generated_icons/#{output_filename}",
            user: request[:user]
          }
        end

        generated_image_urls = []

        generated_entries.each do |entry|
          icon_image_record = IconImage.find_or_create_by!(image: entry[:path]) do |record|
            record.point = 0
          end

          if entry[:user]
            IconImageList.find_or_create_by!(user: entry[:user], image: icon_image_record)
          end

          generated_image_urls << build_image_url(entry[:path])
        end

        render json: { generated_icons: generated_image_urls }, status: :ok
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
        return
      end



      private

      # icon_partsパラメータを配列のハッシュに正規化
      def normalize_icon_parts(data)
        case data
        when nil
          []
        when ActionController::Parameters
          normalize_icon_parts(data.to_unsafe_h)
        when Array
          data.flat_map { |entry| normalize_icon_parts(entry) }.reject(&:blank?)
        when Hash
          [data].reject(&:blank?)
        when String
          begin
            parsed = JSON.parse(data)
            normalize_icon_parts(parsed)
          rescue JSON::ParserError
            []
          end
        else
          []
        end
      end

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

      # paramsのuser_idを検索してUserを取得
      def find_user(user_id)
        User.find_by(id: user_id)
      end

      # パーツごとのuser_idとフォールバックuserから保存対象ユーザーを決定
      def resolve_user_for_parts(parts, fallback_user)
        user_id = parts[:user_id]
        return fallback_user if user_id.nil?

        find_user(user_id)
      end

      def assign_icon_part_images(icon_parts_list, parts)
        parts.each do |type, value|
          next if type == :user_id

          column = resolve_icon_part_column(type)
          next unless column

          image_value = resolve_icon_part_image_value(value)
          next unless image_value.present?

          icon_parts_list.public_send("#{column}=", image_value)
        end
      end

      def resolve_icon_part_column(type)
        type_str = type.to_s

        if type_str.end_with?('_image')
          column = type_str.to_sym
          return column if required_icon_part_columns.include?(column)
        end

        base_name = type_str
        base_name = base_name.delete_suffix('_id') if base_name.end_with?('_id')
        candidate = "#{base_name}_image".to_sym
        required_icon_part_columns.include?(candidate) ? candidate : nil
      end

      def resolve_icon_part_image_value(value)
        return if value.blank?

        # If it's an IconPart id (integer or numeric string)
        if numeric_id?(value)
          icon_part = IconPart.find_by(id: value.to_i)
          return icon_part.image if icon_part
        end

        # Allow direct image path string or look up by path
        if value.is_a?(String)
          icon_part = IconPart.find_by(image: value)
          return icon_part.image if icon_part
          return value
        end

        nil
      end

      def required_icon_part_columns
        @required_icon_part_columns ||= %i[
          eyes_image
          mouth_image
          skin_image
          front_hair_image
          back_hair_image
          eyebrows_image
          high_light_image
          clothing_image
          accessory_image
        ]
      end

      def extract_layer_images(parts)
        layer_images = {}

        parts.each do |key, value|
          next if key == :user_id || value.blank?

          key_str = key.to_s

          if key_str.end_with?('_image')
            layer_key = key_str.delete_suffix('_image').to_sym
            layer_images[layer_key] = value
            next
          end

          case key_str
          when 'background'
            path = resolve_background_image_path(value)
            layer_images[:background] = path if path.present?
          when 'frame'
            path = resolve_frame_image_path(value)
            layer_images[:frame] = path if path.present?
          else
            path = resolve_icon_layer_image(value)
            layer_images[key.to_sym] = path if path.present?
          end
        end

        layer_images
      end

      def resolve_icon_layer_image(value)
        return value if value.is_a?(String)

        if numeric_id?(value)
          icon_part = IconPart.find_by(id: value.to_i)
          return icon_part.image if icon_part
        end

        nil
      end

      def resolve_background_image_path(value)
        return value if value.is_a?(String)

        if numeric_id?(value)
          background = BackgroundImage.find_by(id: value.to_i)
          return background.image if background
        end

        nil
      end

      def resolve_frame_image_path(value)
        return value if value.is_a?(String)

        if numeric_id?(value)
          frame = FrameImage.find_by(id: value.to_i)
          return frame.image if frame
        end

        nil
      end

      def absolute_image_path(image_file)
        return nil if image_file.blank?

        if image_file.start_with?('rails/')
          Rails.root.join(image_file.sub(/^rails\//, ''))
        elsif image_file.start_with?('public/')
          Rails.root.join(image_file)
        elsif image_file.start_with?('/')
          Rails.root.join('public', image_file.delete_prefix('/'))
        else
          Rails.root.join('public', image_file)
        end
      end

      def numeric_id?(value)
        Integer(value, exception: false).present?
      end
    end
  end
end
