module IconAssetsPresenter
  extend ActiveSupport::Concern

  private

  def build_icon_assets_payload(user)
    # アイコンメーカーで必要な各種素材をまとめて取得
    icon_parts = IconPart.includes(:icon_parts_type)
    grouped_parts = icon_parts.group_by { |part| part.icon_parts_type&.content }

    background_images = BackgroundImage.all
    frame_images = FrameImage.all
    icon_images = IconImage.all

    owned_background_ids = user ? user.background_lists.pluck(:image_id) : []
    owned_frame_ids = user ? user.frame_lists.pluck(:image_id) : []
    owned_icon_ids = user ? user.icon_image_lists.pluck(:image_id) : []

    {
      icon_parts: grouped_parts.transform_values { |parts| parts.map(&:as_json) },
      background_images: background_images.map { |image| serialize_with_owned(image, owned_background_ids.include?(image.id)) },
      frame_images: frame_images.map { |image| serialize_with_owned(image, owned_frame_ids.include?(image.id)) },
      icon_images: icon_images.map { |image| serialize_with_owned(image, owned_icon_ids.include?(image.id)) }
    }
  end

  # 各素材にユーザーの保有フラグを付与して返す
  def serialize_with_owned(record, owned)
    record.as_json.merge('owned' => owned)
  end
end
