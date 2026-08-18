class Child::StopSupportMessageService < ProgramMessageService
  def format_data_for_spot_hit(_rcs = false)
    @recipient_data = {}
    @child_ids.each do |child_id|
      child = Child.find(child_id)
      fill_child_name_recipient_data(child.first_name, child.parent1_id)
      fill_redirection_url_recipient_data(child, child.parent1)
      next unless child.parent2

      fill_child_name_recipient_data(child.first_name, child.parent2_id)
      fill_redirection_url_recipient_data(child, child.parent2)
    end
  end

  # Les enfants d'une même fratrie partagent le même parent : leurs prénoms sont
  # agrégés dans le message unique envoyé à ce parent ("Léa et Tom").
  def fill_child_name_recipient_data(first_name, parent_id)
    @recipient_data[parent_id] ||= {}
    if @recipient_data[parent_id]['PRENOM_ENFANT'].present?
      @recipient_data[parent_id]['PRENOM_ENFANT'] += " et #{first_name}"
    else
      @recipient_data[parent_id]['PRENOM_ENFANT'] = first_name
    end
  end

  def fill_redirection_url_recipient_data(child, parent)
    if @redirection_target
      @recipient_data[parent.id] ||= {}
      @recipient_data[parent.id]['URL'] = redirection_url_for_a_parent(parent, child.id)&.decorate&.visit_url
      @url = RedirectionUrl.where(redirection_target: @redirection_target, parent: parent, child: child).first
    end
  end
end
