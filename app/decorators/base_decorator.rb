class BaseDecorator < Draper::Decorator

  delegate_all
  include Rails.application.routes.url_helpers

  def arbre(&block)
    Arbre::Context.new({}, self, &block).to_s
  end

  def tags
    config = h.active_admin_resource_for(model.class)
    return unless config

    arbre do
      model.tags.each do |tag|
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

  def image_link_tag(source, max_width: max_width, max_height: max_height)
    h.image_tag_with_max_size source,
                              max_width: max_width,
                              max_height: max_height,
                              with_link: true,
                              link_options: {
                                target: '_blank'
                              }
  end

end
