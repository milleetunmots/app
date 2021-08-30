module ProgramMessagesHelper

  def get_recipients(term)
    (Parent.where("unaccent(CONCAT(first_name, last_name)) ILIKE unaccent(?)", "%#{term}%").decorate +
        Tag.where("unaccent(name) ILIKE unaccent(?)", "%#{term}%").decorate +
        Group.where("unaccent(name) ILIKE unaccent(?)", "%#{term}%").decorate
    ).map do |result|
      {
        id: "#{result.object.class.name.underscore}.#{result.id}",
        name: result.name,
        type: result.object.class.name.underscore,
        icon: result.icon_class,
        html: result.as_autocomplete_result
      }
    end
  end

  def get_redirection_targets(term)
    RedirectionTarget.joins(:medium)
      .where("media.name ILIKE unaccent(?) and media.url IS NOT NULL", "%#{term}%")
      .decorate.map do |result|
      {
        id: result.id,
        text: result.medium.name
      }
    end
  end

  def get_module(term)
    SupportModule.where("unaccent(name) ILIKE unaccent(?)", "%#{term}%").decorate
      .map do |result|
      {
        id: result.id,
        text: result.name
      }
    end
  end

  def retrieve_messages(module_to_send)
    result = {}
    support_module_week_list = SupportModule.find(module_to_send).support_module_weeks
    support_module_week_list.each_with_index do |support_module_week, index|
      result["support_module_week_#{index + 1}"] = {message_1: {}, message_2: {}, message_3: {}}
      text_message_bundle = Medium.find(support_module_week.medium_id)
      result["support_module_week_#{index + 1}"][:message_1][:body] = text_message_bundle.body1
      result["support_module_week_#{index + 1}"][:message_1][:link] = text_message_bundle.link1_id
      result["support_module_week_#{index + 1}"][:message_2][:body] = text_message_bundle.body2
      result["support_module_week_#{index + 1}"][:message_2][:link] = text_message_bundle.link2_id
      result["support_module_week_#{index + 1}"][:message_3][:body] = text_message_bundle.body3
      result["support_module_week_#{index + 1}"][:message_3][:link] = text_message_bundle.link3_id
      if support_module_week.additional_medium_id
        additional_medium = Medium.find(support_module_week.additional_medium_id)
        result["support_module_week_#{index + 1}"][:message_4] = {}
        result["support_module_week_#{index + 1}"][:message_4][:body] = additional_medium.body1
        result["support_module_week_#{index + 1}"][:message_4][:link] = text_message_bundle.link1_id
      end
    end
    result
  end
end
