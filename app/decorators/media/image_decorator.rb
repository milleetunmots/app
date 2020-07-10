class Media::ImageDecorator < MediumDecorator

  def file_tag(max_width: nil, max_height: nil)
    attached_image_tag model.file, max_width: max_width, max_height: max_height
  end

  def icon_class
    :image
  end

  def preview
    file_tag
  end

end
