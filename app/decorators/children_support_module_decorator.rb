class ChildrenSupportModuleDecorator < BaseDecorator

  def name_display
    return support_module.decorate.admin_link(label: support_module.decorate.name_with_tags) if support_module
    return 'Laisse le choix à 1001mots' if is_completed

    "Pas encore choisi"
  end

  def name_display_for_csv
    return support_module.decorate.name_with_tags if support_module

    return 'Laisse le choix à 1001mots' if is_completed

    'Pas encore choisi'
  end

  def parent_name
    parent.decorate.admin_link
  end

  def parent_name_for_csv
    parent.decorate.name
  end

  def child_name
    child.decorate.admin_link
  end

  def child_name_for_csv
    child.decorate.name
  end

  def name_with_date
    [
      support_module.name,
      choice_date&.strftime('%d/%m/%Y')
    ].reject(&:blank?).join(' - ')
  end

  def available_support_module_names
    model.available_support_modules.map(&:decorate).map { |support_module| support_module.admin_link(label: support_module.name_with_tags) }
  end

  def available_support_module_names_for_csv
    model.available_support_modules.map(&:decorate).map(&:name_with_tags).join("\n")
  end
end
