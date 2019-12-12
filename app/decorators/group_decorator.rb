class GroupDecorator < BaseDecorator

  def admin_link(options = {})
    txt = model.name
    h.link_to txt, [:admin, model], options
  end

  def children
    h.link_to model.children.count, admin_children_path(q: {groups_id_in: [model.id]})
  end

end
