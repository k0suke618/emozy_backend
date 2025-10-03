module IconAssetsPresenter
  extend ActiveSupport::Concern

  private

  def build_icon_assets_payload(user)
    icon_parts = IconPart.includes(:icon_parts_type)
    grouped_parts = icon_parts.group_by { |part| part.icon_parts_type&.content }

    background_images = BackgroundImage.all
    frame_images = FrameImage.all

    owned_background_ids = user ? user.background_lists.pluck(:image_id) : []
    owned_frame_ids = user ? user.frame_lists.pluck(:image_id) : []

    {
      icon_parts: grouped_parts.transform_values { |parts| parts.map(&:as_json) },
      background_images: background_images.map { |image| serialize_with_owned(image, owned_background_ids.include?(image.id)) },
      frame_images: frame_images.map { |image| serialize_with_owned(image, owned_frame_ids.include?(image.id)) }
    }
  end

  def serialize_with_owned(record, owned)
    record.as_json.merge('owned' => owned)
  end
end
