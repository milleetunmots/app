class Media::TextMessagesBundleDecorator < MediumDecorator

  def truncated_body1
    truncated_body model.body1
  end

  def truncated_body2
    truncated_body model.body2
  end

  def truncated_body3
    truncated_body model.body3
  end

  def image1_tag(max_width: nil, max_height: nil)
    attached_image_tag model.image1, max_width: max_width, max_height: max_height
  end

  def image2_tag(max_width: nil, max_height: nil)
    attached_image_tag model.image2, max_width: max_width, max_height: max_height
  end

  def image3_tag(max_width: nil, max_height: nil)
    attached_image_tag model.image3, max_width: max_width, max_height: max_height
  end

  def link1_tag
    link_tag model.link1
  end

  def link2_tag
    link_tag model.link2
  end

  def link3_tag
    link_tag model.link3
  end

  def icon_class
    :comments
  end

  def preview
    arbre do
      div class: 'body-image' do
        div class: 'body' do
          model.body1
        end
        div class: 'image' do
          image1_tag
        end
      end
      div class: 'body-image' do
        div class: 'body' do
          model.body2
        end
        div class: 'image' do
          image2_tag
        end
      end
      div class: 'body-image' do
        div class: 'body' do
          model.body3
        end
        div class: 'image' do
          image3_tag
        end
      end
    end
  end

  private

  def truncated_body(v)
    v&.truncate 160,
                separator: /\s/,
                omission: ' (…)'
  end

  def attached_image_tag(attached, max_width: nil, max_height: nil)
    return if attached.nil?
    attached.decorate.file_tag(max_width: max_width, max_height: max_height)
  end

  def link_tag(link)
    link&.decorate&.admin_link
  end

end
