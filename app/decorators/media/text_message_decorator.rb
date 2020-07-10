class Media::TextMessageDecorator < MediumDecorator

  def truncated_body
    model.body.truncate 100,
                        separator: /\s/,
                        omission: ' (…)'
  end

  def image_tag(max_width: nil, max_height: nil)
    attached_image_tag model.image, max_width: max_width, max_height: max_height
  end

  def icon_class
    :sms
  end

  def preview
    arbre do
      div class: 'body-image' do
        div class: 'body' do
          model.body
        end
        div class: 'image' do
          image_tag
        end
      end
    end
  end

end
