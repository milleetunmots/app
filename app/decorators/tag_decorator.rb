class TagDecorator < BaseDecorator

  def colored_color
    h.content_tag :span, model.color, style: "color: #{model.color}"
  end

  def as_autocomplete_result
    h.content_tag :div, class: 'tag-autocomplete' do
      h.content_tag :div, class: :name do
        name
      end
    end
  end

  def icon_class
    :tag
  end

end
