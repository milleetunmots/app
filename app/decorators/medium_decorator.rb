class MediumDecorator < BaseDecorator

  def type_name
    model.type.constantize.model_name.human
  end

  def css_class_name
    model.type.split('::').last.underscore.gsub('_', '-')
  end

  protected

  def attached_image_tag(attached, max_width: nil, max_height: nil)
    return unless attached.attached?
    style = []
    style << "max-width: #{max_width}" if max_width
    style << "max-height: #{max_height}" if max_height
    h.image_tag attached,
                style: style.join(';')
  end

end
