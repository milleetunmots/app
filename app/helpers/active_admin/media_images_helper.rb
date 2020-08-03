module ActiveAdmin::MediaImagesHelper

  def media_image_select_collection
    Media::Image.order(:name).map(&:decorate)
  end

end
