class MediumDecorator < BaseDecorator

  def admin_link(options = {})
    with_icon = options.delete(:with_icon)

    txt = options.delete(:label) || name
    if with_icon
      txt = h.content_tag(:i, '', class: "fas fa-#{icon_class}") + "&nbsp;".html_safe + txt
    end
    options[:class] = [
      options[:class],
      model.discarded? ? 'discarded' : 'kept'
    ].compact.join(' ')
    h.link_to txt, [:admin, model], options
  end

  def type_name
    model.type.constantize.model_name.human
  end

  def css_class_name
    model.type.split('::').last.underscore.gsub('_', '-')
  end

  protected

  def attached_image_link(attached)
    return unless attached.attached?
    txt = attached.blob.filename.to_s + '&nbsp;' + h.content_tag(:i, '', class: 'fas fa-external-link-alt')
    h.link_to txt.html_safe, h.rails_blob_path(attached, disposition: "attachment"), target: '_blank'
  end

  def attached_image_tag(attached, max_width: nil, max_height: nil)
    return unless attached.attached?
    style = []
    style << "max-width: #{max_width}" if max_width
    style << "max-height: #{max_height}" if max_height
    h.link_to attached, target: '_blank' do
      h.image_tag attached,
                  style: style.join(';')
    end
  end

end
