class MediumDecorator < BaseDecorator

  def folder_link(options = {})
    folder&.decorate&.admin_link(options)
  end

  def type_name
    model.type.constantize.model_name.human
  end

  def css_class_name
    model.type.split('::').last.underscore.gsub('_', '-')
  end

  def as_autocomplete_result
    h.content_tag :div, class: "medium" do
      (
        h.content_tag :div, class: :name do
          name
        end
      )
    end
  end
end
