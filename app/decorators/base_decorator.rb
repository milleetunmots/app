class BaseDecorator < Draper::Decorator

  delegate_all
  include Rails.application.routes.url_helpers

  def arbre(&block)
    Arbre::Context.new({}, self, &block).to_s
  end

  def admin_link(options = {})
    with_icon = options.delete(:with_icon)

    txt = options.delete(:label) || name
    if with_icon
      txt = h.content_tag(:i, '', class: "fas fa-#{icon_class}") + "&nbsp;".html_safe + txt
    end
    options[:class] = [
      options[:class],
      model.respond_to?(:discarded?) && (model.discarded? ? 'discarded' : 'kept')
    ].compact.join(' ')
    h.link_to txt, [:admin, model], options
  end

  def tags(options = {})
    return unless options[:context]

    config = h.active_admin_resource_for(model.class)
    return unless config

    arbre do
      model.send(options[:context]).each do |tag|
        a tag.name,
          href: config.route_collection_path(nil, q: {tagged_with_all: [tag.name]}),
          class: 'tag',
          style: "background-color: #{tag.color || '#CACACA'}"
        text_node "&nbsp;".html_safe
      end
    end
  end

  def created_at_date
    h.l model.created_at.to_date, format: :default
  end

  def updated_at_date
    h.l model.updated_at.to_date, format: :default
  end

  def image_link_tag(source, max_width: nil, max_height: nil)
    h.image_tag_with_max_size source,
                              max_width: max_width,
                              max_height: max_height,
                              with_link: true,
                              link_options: {
                                target: '_blank'
                              }
  end

end
