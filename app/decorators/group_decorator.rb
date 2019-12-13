class GroupDecorator < BaseDecorator

  def admin_link(options = {})
    options[:class] = [options[:class], 'group-admin-link'].compact.join(' ')
    if model.is_ended?
      options[:class] = [options[:class], 'ended'].join(' ')
    end

    h.link_to model.name, [:admin, model], options
  end

  def children
    h.link_to model.children.count, admin_children_path(q: {group_id_in: [model.id]})
  end

end
