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

end
