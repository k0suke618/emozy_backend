module Api
  module V1
    class IconMakerController < ApplicationController
      protect_from_forgery with: :null_session

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
        
        icon_parts_data = params[:icon_parts]
        normalized_parts = normalize_icon_parts(icon_parts_data)
        if normalized_parts.blank?
          render json: { error: 'Invalid icon parts data' }, status: :bad_request
          return
        end

        fallback_user = find_user(params[:user_id]) if params[:user_id].present?
        icon_parts_lists = []

        normalized_parts.each do |parts|
          typed_parts = parts.deep_symbolize_keys
          user = resolve_user_for_parts(typed_parts, fallback_user)
          unless user
            render json: { error: 'User not found' }, status: :bad_request
            return
          end

          icon_parts_list = IconPartsList.new(user: user)
          typed_parts.each do |type, part_id|
            next if type == :user_id

            icon_part = IconPart.find_by(id: part_id)
            next unless icon_part

            column_name = "#{type}_image"
            if icon_parts_list.respond_to?("#{column_name}=")
              icon_parts_list.send("#{column_name}=", icon_part.image)
            end
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

      private

      # icon_partsパラメータを配列のハッシュに正規化
      def normalize_icon_parts(icon_parts_data)
        case icon_parts_data
        when Array
          icon_parts_data.map { |parts| safe_to_hash(parts) }.compact
        when ActionController::Parameters, Hash
          [safe_to_hash(icon_parts_data)].compact
        else
          []
        end
      end

      # ActionController::Parameters を含む値をハッシュに変換
      def safe_to_hash(parts)
        if parts.respond_to?(:to_unsafe_h)
          parts.to_unsafe_h
        elsif parts.is_a?(Hash)
          parts
        else
          nil
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
    end
  end
end
