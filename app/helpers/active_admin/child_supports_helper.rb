module ActiveAdmin::ChildSupportsHelper

  def child_support_supporter_select_collection
    AdminUser.order(:name).map(&:decorate)
  end

  ### shared

  def child_support_call_language_awareness_select_collection
    ChildSupport::LANGUAGE_AWARENESS.map do |v|
      [
        ChildSupport.human_attribute_name("call_language_awareness.#{v}"),
        v
      ]
    end
  end

  def child_support_call_parent_progress_select_collection
    ChildSupport::PARENT_PROGRESS.map do |v|
      [
        ChildSupport.human_attribute_name("call_parent_progress.#{v}"),
        v
      ]
    end
  end

  def child_support_call_reading_frequency_select_collection
    ChildSupport::READING_FREQUENCY.reverse.map do |v|
      [
        ChildSupport.human_attribute_name("call_reading_frequency.#{v}"),
        v
      ]
    end
  end

  def child_support_call_tv_frequency_select_collection
    ChildSupport::TV_FREQUENCY.reverse.map do |v|
      [
        ChildSupport.human_attribute_name("call_tv_frequency.#{v}"),
        v
      ]
    end
  end

  def child_support_call_sendings_benefits_select_collection
    ChildSupport::SENDINGS_BENEFITS.map do |v|
      [
        ChildSupport.human_attribute_name("call_sendings_benefits.#{v}"),
        v
      ]
    end
  end

  def child_support_call_family_progress_select_collection
    ChildSupport::FAMILY_PROGRESS.map do |v|
      [
        ChildSupport.human_attribute_name("call_family_progress.#{v}"),
        v
      ]
    end
  end

  def child_support_call_previous_goals_follow_up_select_collection
    ChildSupport::GOALS_FOLLOW_UP.map do |v|
      [
        ChildSupport.human_attribute_name("call_previous_goals_follow_up.#{v}"),
        v
      ]
    end
  end

  def child_support_books_quantity
    ChildSupport::BOOKS_QUANTITY.map do |v|
      [
        ChildSupport.human_attribute_name("books_quantity.#{v}"),
        v
      ]
    end
  end

  def social_network_collection
    ChildSupport::SOCIAL_NETWORK.map { |v| ChildSupport.human_attribute_name("social_network.#{v}") }
  end

  def our_social_network_collection
    ChildSupport::OUR_SOCIAL_NETWORK.map { |v| ChildSupport.human_attribute_name("our_social_network.#{v}") }
  end

  def book_not_received_collection
    ChildSupport::BOOK_NOT_RECEIVED.map { |v| ChildSupport.human_attribute_name("book_not_received.#{v}") }
  end

  def call_status_collection
    ChildSupport::CALL_STATUS.map { |v| ChildSupport.human_attribute_name("call_status.#{v}") }
  end

  def is_bilingual_collection
    ChildSupport::IS_BILINGUAL_OPTIONS.map do |v|
      [
        ChildSupport.human_attribute_name("is_bilingual.#{v}"),
        v
      ]
    end
  end

  def instagram_information_collection
    ChildSupport::INSTAGRAM_INFORMATION_OPTIONS.map do |v|
      [
        ChildSupport.human_attribute_name("instagram_information.#{v}"),
        v
      ]
    end
  end

  def call_statuses_with_nil
    ChildSupport::CALL_STATUS.map do |v|
      [
        ChildSupport.human_attribute_name("call_status.#{v}"),
        ChildSupport.human_attribute_name("call_status.#{v}")
      ]
    end.push(['Non renseigné', 'nil'])
  end

  def important_information_with_typeform_link(important_information, admin_user_id)
    return important_information unless ENV['TYPEFORM_LINK_SUPPORTERS_IDS'].split(',').map(&:to_i).include? admin_user_id

    if important_information.present? && important_information.include?('https://form.typeform.com/to/ezCyiRZJ')
      important_information
    else
      "Enquête prise de RDV > https://form.typeform.com/to/ezCyiRZJ \n#{important_information}"
    end
  end

  def resources_alternative_script_links
    {
      'Pratiques très avancées' => ENV['ALTERNATIVE_SCRIPT_POPI_LINK'],
      'Ne veut pas des SMS/Appels' => ENV['ALTERNATIVE_SCRIPT_NO_SMS_CALLS_SCRIPT_LINK'],
      'Comportement problématique' => ENV['ALTERNATIVE_SCRIPT_PROBLEMATIC_BEHAVIOR_SCRIPT_LINK'],
      'Professionnel qui teste 1001mots' => ENV['ALTERNATIVE_SCRIPT_PROFESSIONAL_TEST_SCRIPT_LINK'],
      'Inscription sans accord' => ENV['ALTERNATIVE_SCRIPT_REGISTRATION_WITHOUT_AGREEMENT_SCRIPT_LINK'],
      'Pas assez francophone' => ENV['ALTERNATIVE_SCRIPT_NOT_ENOUGH_FRENCH_SCRIPT_LINK']
    }
  end

  def resources_briefing_link(call_idx)
    case call_idx
    when 0 then ENV['ALTERNATIVE_SCRIPT_CALL0_BRIEFING_LINK']
    when 1 then ENV['ALTERNATIVE_SCRIPT_CALL1_BRIEFING_LINK']
    when 2 then ENV['ALTERNATIVE_SCRIPT_CALL2_BRIEFING_LINK']
    when 3 then ENV['ALTERNATIVE_SCRIPT_CALL3_BRIEFING_LINK']
    end
  end

  def resources_recommended_video_link(call_idx, child_age_in_months)
    case call_idx
    when 0
      if child_age_in_months < 11
        return ENV['ALTERNATIVE_SCRIPT_VIDEO_CALL0_CHILD_0_10_MONTHS_LINK']
      elsif child_age_in_months >= 11 && child_age_in_months <= 16
        return ENV['ALTERNATIVE_SCRIPT_VIDEO_CALL0_CHILD_11_16_MONTHS_LINK']
      elsif child_age_in_months >= 17 && child_age_in_months <= 22
        return ENV['ALTERNATIVE_SCRIPT_VIDEO_CALL0_CHILD_17_22_MONTHS_LINK']
      elsif child_age_in_months >= 23
        return ENV['ALTERNATIVE_SCRIPT_VIDEO_CALL0_CHILD_23_MORE_MONTHS_LINK']
      end
    when 1
      if child_age_in_months < 12
        return ENV['ALTERNATIVE_SCRIPT_VIDEO_CALL1_CHILD_0_11_MONTHS_LINK']
      elsif child_age_in_months >= 12 && child_age_in_months <= 17
        return ENV['ALTERNATIVE_SCRIPT_VIDEO_CALL1_CHILD_12_17_MONTHS_LINK']
      elsif child_age_in_months >= 18 && child_age_in_months <= 23
        return ENV['ALTERNATIVE_SCRIPT_VIDEO_CALL1_CHILD_18_23_MONTHS_LINK']
      elsif child_age_in_months >= 24
        return ENV['ALTERNATIVE_SCRIPT_VIDEO_CALL1_CHILD_24_MORE_MONTHS_LINK']
      end
    when 3
      return [ENV['ALTERNATIVE_SCRIPT_VIDEO_CALL3_OBSERVEZ_LINK'], ENV['ALTERNATIVE_SCRIPT_VIDEO_CALL3_PARLEZ_LINK']]
    end
  end
end
