class GroupDecorator < BaseDecorator

  def admin_link(options = {})
    options[:class] = [
      options[:class],
      'group-admin-link',
      model.discarded? ? 'discarded' : 'kept',
      model.is_ended? ? 'ended' : 'not-ended'
    ].compact.join(' ')

    h.link_to model.name, [:admin, model], options
  end

  def children
    h.link_to model.children.count, admin_children_path(q: {group_id_in: [model.id]})
  end

  def as_autocomplete_result
    h.content_tag :div, class: 'group' do
      h.content_tag :div, class: :name do
        name
      end
    end
  end

  def icon_class
    :users
  end

end
