class ChildrenSupportModuleDecorator < BaseDecorator

  def name_with_date
    [
      support_module.name,
      updated_at.strftime('%d/%m/%Y')
    ].reject(&:blank?).join(' - ')
  end

end
