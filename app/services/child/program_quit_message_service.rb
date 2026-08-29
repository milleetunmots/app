class Child::ProgramQuitMessageService < ProgramMessageService

  def format_data_for_spot_hit(_rcs = false)
    @recipient_data = {}
    @child_ids.each do |child_id|
      child = Child.find(child_id)
      add_recipient(child, child.parent1_id) if child.should_contact_parent1
      add_recipient(child, child.parent2_id) if child.should_contact_parent2
    end
  end

  def add_recipient(child, parent_id)
    return if parent_id.blank? || !@parent_ids.include?(parent_id)

    @recipient_data[parent_id] = {
      'QUIT_LINK' => Rails.application.routes.url_helpers.edit_child_url(
        id: child.id,
        security_code: child.security_code
      )
    }
    @event_params[parent_id] = { quit_group_child_id: child.id }
  end
end
