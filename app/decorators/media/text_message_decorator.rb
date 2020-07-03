class Media::TextMessageDecorator < MediumDecorator

  def truncated_body
    model.body.truncate 100,
                        separator: /\s/,
                        omission: ' (…)'
  end

end
