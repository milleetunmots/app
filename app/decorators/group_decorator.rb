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
    h.link_to model.children.kept.count, admin_children_path(q: {group_id_in: [model.id]})
  end

  def families
    h.link_to model.child_supports.kept.with_kept_children.where(children: { group_status: 'active' }).distinct.count, admin_child_supports_path(q: {group_id_in: [model.id]})
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

  def type_of_support
    Group.human_attribute_name("type_of_support.#{model.type_of_support}")
  end

end
