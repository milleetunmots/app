class ChildrenSupportModuleDecorator < BaseDecorator

  def name
    return support_module.decorate&.admin_link if support_module
    return "Laisse le choix à 1001mots" if is_completed

    "Pas encore choisi"
  end

  def parent_name
    parent.decorate.admin_link
  end

  def child_name
    child.decorate.admin_link
  end

  def name_with_date
    [
      support_module.name,
      choice_date&.strftime('%d/%m/%Y')
    ].reject(&:blank?).join(' - ')
  end

  def available_support_module_names
    model.available_support_modules.map { |support| support.decorate&.admin_link }
  end

end
