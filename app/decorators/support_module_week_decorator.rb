class SupportModuleWeekDecorator < BaseDecorator

  def title(number = model.position)
    "Semaine #{number}&nbsp;: #{model.name}".html_safe
  end

  def support_module_link(options = {})
    model.support_module&.decorate&.admin_link(options)
  end

  def medium_link(options = {})
    model.medium&.decorate&.admin_link(options)
  end

end
