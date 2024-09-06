module ProgramMessagesHelper

  def format_recipient(recipient)
    {
      id: "#{recipient.object.class.name.underscore}.#{recipient.id}",
      name: recipient.name,
      type: recipient.object.class.name.underscore,
      icon: recipient.icon_class,
      html: recipient.as_autocomplete_result,
      selected: true
    }
  end

  def format_result(result)
    {
      id: result.id,
      text: result.medium.name
    }
  end

  def child_age_range_for_module_zero(parent_decorated)
    case parent_decorated.object.current_child&.months
    when 4..10
      '4-10'
    when 11..16
      '11-16'
    when 17..22
      '17-22'
    when 23..31
      '23-31'
    end
  end

  def child_age_range(parent_decorated)
    case parent_decorated.object.current_child&.months
    when 4..11
      '06-11'
    when 12..17
      '12-17'
    when 18..23
      '18-23'
    when 24..31
      '24-31'
    end
  end

  def module_zero_suggested_video(child_age_range)
    return unless child_age_range

    video = RedirectionTarget.joins(:medium).where("media.name LIKE ?", "#{RedirectionTarget::SUGGESTED_VIDEOS_MODULE_0_NAME_STARTS_WITH} - #{child_age_range}%").first
    video&.decorate
  end

  def module_one_suggested_video(child_age_range)
    video = RedirectionTarget.joins(:medium).find_by(media: { name: "#{RedirectionTarget::SUGGESTED_VIDEOS_MODULE_1_NAME_STARTS_WITH} - #{child_age_range}" })
    video&.decorate
  end

  def call3_suggested_videos
    videos = RedirectionTarget.joins(:medium).where('media.name LIKE ?', "#{RedirectionTarget::SUGGESTED_VIDEOS_CALL_3_NAME_STARTS_WITH} - %")
    return if videos.empty?

    videos.map { |video| format_result(video.decorate) }
  end

  def suggested_videos(parent_decorated)
    suggested_videos = []
    module_zero_video = module_zero_suggested_video(child_age_range_for_module_zero(parent_decorated))
    module_one_video = module_one_suggested_video(child_age_range(parent_decorated))
    suggested_videos << format_result(module_zero_video) if module_zero_video
    suggested_videos << format_result(module_one_video) if module_one_video
    suggested_videos += call3_suggested_videos if call3_suggested_videos
    suggested_videos
  end

  def get_recipients(term, parent_decorated = nil)
    unless parent_decorated
      return (Parent.where("unaccent(CONCAT(first_name, last_name)) ILIKE unaccent(?)", "%#{term}%").decorate +
        Tag.where("unaccent(name) ILIKE unaccent(?)", "%#{term}%").decorate +
        Group.where("unaccent(name) ILIKE unaccent(?)", "%#{term}%").decorate
      ).map { |result| format_recipient(result) }
    end

    [format_recipient(parent_decorated).merge({ selected: true })]
  end

  def get_redirection_targets(term, parent_decorated = nil)
    redirection_targets = RedirectionTarget.kept
                                           .joins(:medium)
                                           .where("media.name ILIKE unaccent(?) and media.url IS NOT NULL and media.discarded_at IS NULL", "%#{term}%")
                                           .decorate.map { |result| format_result(result) }

    return redirection_targets unless parent_decorated

    [
      { text: 'Vidéos suggérées pour ce parent', children: suggested_videos(parent_decorated) },
      { text: 'Autres vidéos', children: redirection_targets }
    ]
  end

  def get_module(term)
    SupportModule.where("unaccent(name) ILIKE unaccent(?)", "%#{term}%").decorate
      .map do |result|
      {
        id: result.id,
        text: result.name_with_tags
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

  def get_supporter(term, supporter_decorated = nil)
    unless supporter_decorated
      return AdminUser.supporters.where("unaccent(name) ILIKE unaccent(?)", "%#{term}%").decorate.map do |result|
        {
          id: result.id,
          text: result.name
        }
      end
    end

    [{ id: supporter_decorated.id, text: supporter_decorated.name, selected: true }]
  end

  def get_spot_hit_file(image_id)
    Medium.find(image_id).spot_hit_id unless image_id.nil?
  end

  def retrieve_messages(module_to_send)
    result = {}
    support_module_week_list = SupportModuleWeek.where("support_module_id = ?", module_to_send).order(:position)
    support_module_week_list.each_with_index do |support_module_week, index|
      result["support_module_week_#{index + 1}"] = {message_1: {}, message_2: {}, message_3: {}}
      next unless support_module_week.medium_id

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
      next unless support_module_week.additional_medium_id

      additional_medium = Medium.find(support_module_week.additional_medium_id)
      result["support_module_week_#{index + 1}"][:message_4] = {}
      result["support_module_week_#{index + 1}"][:message_4][:body] = additional_medium.body1
      result["support_module_week_#{index + 1}"][:message_4][:link] = RedirectionTarget.where(medium_id: additional_medium.link1_id).first&.id
      result["support_module_week_#{index + 1}"][:message_4][:file] = Medium.where("type = ? and id = ?", "Media::Image", text_message_bundle.image1_id).first
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
