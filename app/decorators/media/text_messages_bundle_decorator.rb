class Media::TextMessagesBundleDecorator < MediumDecorator

  def truncated_body1
    model.body1.truncate 50,
                        separator: /\s/,
                        omission: ' (…)'
  end

  def truncated_body2
    model.body2.truncate 50,
                        separator: /\s/,
                        omission: ' (…)'
  end

  def truncated_body3
    model.body3.truncate 50,
                        separator: /\s/,
                        omission: ' (…)'
  end

  def icon_class
    :comments
  end

  def preview
    arbre do
      div class: 'body1' do
        model.body1
      end
      div class: 'body2' do
        model.body2
      end
      div class: 'body3' do
        model.body3
      end
    end
  end

end
