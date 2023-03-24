class Child::ProgramQuitMessageService < ProgramMessageService

  def format_data_for_spot_hit
    @recipient_data = {}
    @child_ids.each do |child_id|
      child = Child.find(child_id)
      @recipient_data[child.parent1_id.to_s] = {}
      @recipient_data[child.parent1_id.to_s]['QUIT_LINK'] = Rails.application.routes.url_helpers.edit_child_url(
        id: child_id,
        security_code: child.security_code
      )

      @event_params[child.parent1_id.to_s] = { quit_group_child_id: child_id }
      next unless child.parent2

      @recipient_data[child.parent2_id&.to_s] = {}
      @recipient_data[child.parent2_id&.to_s]['QUIT_LINK'] = Rails.application.routes.url_helpers.edit_child_url(
        id: child_id,
        security_code: child.security_code
      )
      @event_params[child.parent2_id.to_s] = { quit_group_child_id: child_id }
    end
  end
end
