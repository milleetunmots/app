module ActiveAdmin::ImagesHelper

  # add support for :
  # - link_options
  # - max_height
  # - max_width
  # - with_link
  def image_tag_with_max_size(**options)
    options = options.symbolize_keys
    max_width = options.delete(:max_width)
    max_height = options.delete(:max_height)
    with_link = options.delete(:with_link)
    link_options = options.delete(:link_options)
    source = options.delete(:source)

    # max size

    style = []
    style << "max-width: #{max_width};" if max_width
    style << "max-height: #{max_height};" if max_height
    style << options.delete(:style)

    # tag itself

    if Rails.application.config.active_storage.service == 'minio'
      url = source.blob.url.gsub('http://minio:9000', "https://#{ENV['DEFAULT_HOSTNAME']}").split('?').first
      tag = image_tag url, options.merge(style: style.join)
    else
      tag = image_tag source, options.merge(style: style.join)
    end

    # link

    if with_link
      link_to tag, source, link_options
    else
      tag
    end
  end

end
