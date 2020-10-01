class SupportModuleWeekDecorator < BaseDecorator

  def title(number = model.position)
    start = model.support_module.start_at
    if start
      monday = start + (number - 1).weeks
      "Semaine du #{I18n.l(monday, format: :long)}"
    else
      "Semaine #{number}"
    end
  end

  def support_module_link(options = {})
    model.support_module&.decorate&.admin_link(options)
  end

  def medium_link(options = {})
    model.medium&.decorate&.admin_link(options)
  end

end
