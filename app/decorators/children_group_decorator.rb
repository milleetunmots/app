class ChildrenGroupDecorator < BaseDecorator

  def admin_link(options = {})
    txt = model.group.name

    if model.group.is_ended?
      txt += " (terminée le #{h.l model.group.ended_at})"
    elsif model.has_quit?
      txt += " (quittée le #{h.l model.quit_at})"
    else
      options[:class] = :blue
    end

    h.link_to txt, [:admin, model.group], options
  end

end
