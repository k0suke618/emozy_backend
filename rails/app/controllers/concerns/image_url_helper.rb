module ImageUrlHelper
  def build_image_url(path)
    return nil if path.blank?
    return path if path.start_with?('http://', 'https://')

    normalized = path.dup
    normalized = normalized.sub(/^rails\//, '')
    normalized = normalized.sub(/^public\//, '')
    normalized = normalized.sub(%r{^/+}, '')

    "#{request.base_url}/#{normalized}"
  end
end
