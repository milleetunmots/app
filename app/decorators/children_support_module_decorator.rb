class ChildrenSupportModuleDecorator < BaseDecorator

  def group
    child.group&.name
  end

  def parent_name
    parent.decorate.name
  end

  def child_name
    child.decorate.name
  end

  def name_with_date
    [
      support_module.name,
      choice_date&.strftime('%d/%m/%Y')
    ].reject(&:blank?).join(' - ')
  end

  def available_support_module_names
    model.available_support_modules.pluck(:name)
  end

end
