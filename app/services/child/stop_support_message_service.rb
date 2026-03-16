class Child::StopSupportMessageService < ProgramMessageService
  def format_data_for_spot_hit(_rcs = false)
    @recipient_data = {}
    @child_ids.each do |child_id|
      child = Child.find(child_id)
      fill_child_name_recipient_data(child.first_name, child.parent1.phone_number)
      fill_redirection_url_recipient_data(child, child.parent1)
      next unless child.parent2

      fill_child_name_recipient_data(child.first_name, child.parent2.phone_number)
      fill_redirection_url_recipient_data(child, child.parent2)
    end
  end

  def fill_child_name_recipient_data(first_name, phone_number)
    @recipient_data[phone_number] ||= {}
    if @recipient_data[phone_number]['PRENOM_ENFANT'].present?
      @recipient_data[phone_number]['PRENOM_ENFANT'] += " et #{first_name}"
    else
      @recipient_data[phone_number]['PRENOM_ENFANT'] = first_name
    end
  end

  def fill_redirection_url_recipient_data(child, parent)
    if @redirection_target
      @recipient_data[parent.phone_number] ||= {}
      @recipient_data[parent.phone_number]['URL'] = redirection_url_for_a_parent(parent, child.id)&.decorate&.visit_url
      @url = RedirectionUrl.where(redirection_target: @redirection_target, parent: parent, child: child).first
    end
  end
end
