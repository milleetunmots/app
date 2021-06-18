class TagDecorator < BaseDecorator

  def colored_color
    h.content_tag :span, model.color, style: "color: #{model.color}"
  end

end
