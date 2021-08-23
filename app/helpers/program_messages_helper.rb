module ProgramMessagesHelper

  def get_recipients(term)
    (Parent.where("unaccent(CONCAT(first_name, last_name)) ILIKE unaccent(?)", term).decorate +
        Tag.where("unaccent(name) ILIKE unaccent(?)", term).decorate +
        Group.where("unaccent(name) ILIKE unaccent(?)", term).decorate
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
      .where("media.name ILIKE unaccent(?) and media.url IS NOT NULL", term)
      .decorate.map do |result|
      {
        id: result.id,
        text: result.medium.name
      }
    end
  end

  def get_module(term)
    SupportModule.where("unaccent(name) ILIKE unaccent(?)", term).decorate
      .map do |result|
      {
        id: result.id,
        text: result.name
      }
    end
  end

  def sort_recipients(recipients)
    result = {parent_ids: [], tag_ids: [], group_ids: []}
    recipients&.each do |recipient_id|
      if recipient_id.include? "parent."
        result[:parent_ids] << recipient_id[/\d+/].to_i
      elsif recipient_id.include? "tag."
        result[:tag_ids] << recipient_id[/\d+/].to_i
      elsif recipient_id.include? "group."
        result[:group_ids] << recipient_id[/\d+/].to_i
      end
    end
    result
  end

  def retrieve_messages(module_to_send)
    result = {}
    support_module_week_list = SupportModule.find(module_to_send).support_module_weeks
    support_module_week_list.each_with_index do |support_module_week, index|
      result["support_module_week_#{index + 1}"] = {}
      text_message_bundle = Medium.find(support_module_week.medium_id)
      result["support_module_week_#{index + 1}"][:message_1] = text_message_bundle.body1
      result["support_module_week_#{index + 1}"][:message_2] = text_message_bundle.body2
      result["support_module_week_#{index + 1}"][:message_3] = text_message_bundle.body3
      if support_module_week.additional_medium_id
        additional_medium = Medium.find(support_module_week.additional_medium_id)
        result["support_module_week_#{index + 1}"][:message_4] = additional_medium.body1
      end
    end
    result
  end

end
