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

  def get_image_to_send(term)
    Medium.where("type = ? and unaccent(name) ILIKE unaccent(?)", "Media::Image", "%#{term}%")
      .decorate
      .map do |result|
      {
        id: result.id,
        text: result.name
      }
    end
  end

  def get_spot_hit_file(image_id)
    Medium.find(image_id).spot_hit_id unless image_id.nil?
  end

  def retrieve_messages(module_to_send)
    result = {}
    support_module_week_list = SupportModuleWeek.where("support_module_id = ?", module_to_send)
    support_module_week_list.each_with_index do |support_module_week, index|
      result["support_module_week_#{index + 1}"] = {message_1: {}, message_2: {}, message_3: {}}
      text_message_bundle = Medium.find(support_module_week.medium_id)
      result["support_module_week_#{index + 1}"][:message_1][:body] = text_message_bundle.body1
      result["support_module_week_#{index + 1}"][:message_1][:link] = RedirectionTarget.where(medium_id: text_message_bundle.link1_id).first&.id
      result["support_module_week_#{index + 1}"][:message_1][:file] = Medium.where("type = ? and id = ?", "Media::Image", text_message_bundle.image1_id).first
      result["support_module_week_#{index + 1}"][:message_2][:body] = text_message_bundle.body2
      result["support_module_week_#{index + 1}"][:message_2][:link] = RedirectionTarget.where(medium_id: text_message_bundle.link2_id).first&.id
      result["support_module_week_#{index + 1}"][:message_2][:file] = Medium.where("type = ? and id = ?", "Media::Image", text_message_bundle.image2_id).first
      result["support_module_week_#{index + 1}"][:message_3][:body] = text_message_bundle.body3
      result["support_module_week_#{index + 1}"][:message_3][:link] = RedirectionTarget.where(medium_id: text_message_bundle.link3_id).first&.id
      result["support_module_week_#{index + 1}"][:message_3][:file] = Medium.where("type = ? and id = ?", "Media::Image", text_message_bundle.image3_id).first
      if support_module_week.additional_medium_id
        additional_medium = Medium.find(support_module_week.additional_medium_id)
        result["support_module_week_#{index + 1}"][:message_4] = {}
        result["support_module_week_#{index + 1}"][:message_4][:body] = additional_medium.body1
        result["support_module_week_#{index + 1}"][:message_4][:link] = RedirectionTarget.where(medium_id: additional_medium.link1_id).first&.id
        result["support_module_week_#{index + 1}"][:message_4][:file] = Medium.where("type = ? and id = ?", "Media::Image", text_message_bundle.image1_id).first
      end
    end
    result
  end

  def manage_messages_date(date, support_module_week)
    return date.next_day(2) if date.tuesday?
    return date.next_day(3) if date.saturday?
    if support_module_week.length == 3
      return date.next_day(2) if date.thursday?
    else
      return date.next_day if date.thursday?
      return date.next_day if date.friday?
    end
  end

  def set_messages_sent(module_to_send)
    support_module_week_list = SupportModule.find(module_to_send).support_module_weeks
    support_module_week_list.each do |support_module_week|
      support_module_week.update! has_been_sent1: true, has_been_sent2: true, has_been_sent3: true
      support_module_week.update! has_been_sent4: true if support_module_week.additional_medium_id
    end
  end
end
