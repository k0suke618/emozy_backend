module ImageUrlHelper
  def build_image_url(path)
    return nil if path.blank?
    return path if path.start_with?('http://', 'https://')
    "#{request.base_url}/#{path}"
  end
end
