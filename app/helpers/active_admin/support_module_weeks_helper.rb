module ActiveAdmin::SupportModuleWeeksHelper

  def support_module_week_medium_select_collection
    Media::TextMessagesBundle.order(:name).map(&:decorate)
  end

  def support_module_week_additional_medium_select_collection
    Media::TextMessagesBundle.single_message.order(:name).map(&:decorate)
  end

end
