class ScheduledCallDecorator < BaseDecorator

  def display_name
    "RDV Calendly - Appel #{model.call_session} - #{model.parent.decorate.name}"
  end

  def child_support
    return unless model.child_support

    helpers.link_to('Voir le suivi',
                    helpers.edit_admin_child_support_path(model.child_support),
                    target: '_blank',
                    style: 'text-decoration: underline;')
  end

  def group
    return unless model.group

    model.group.decorate.admin_link
  end

  def parent
    return unless model.parent

    model.parent.decorate.admin_link
  end

  def children
    return unless model.children&.any?

    model.children.map(&:first_name).join(', ')
  end
end
