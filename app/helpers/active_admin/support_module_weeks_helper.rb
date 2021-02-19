module ActiveAdmin::SupportModuleWeeksHelper

  def support_module_week_medium_select_collection
    Media::TextMessagesBundle.order(:name)
                             .map do |msg|
      [
        msg.decorate.select_collection_option_label,
        msg.id
      ]
    end
  end

  def support_module_week_additional_medium_select_collection
    Media::TextMessagesBundle.single_message
                             .order(:name)
                             .map do |msg|
      [
        msg.decorate.select_collection_option_label,
        msg.id
      ]
    end
  end

end
