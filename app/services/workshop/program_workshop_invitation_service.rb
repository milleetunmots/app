class Workshop::ProgramWorkshopInvitationService < ProgramMessageService

  def format_data_for_spot_hit(_rcs = false)
    @recipient_data = {}
    parents = Parent.where(id: @parent_ids, is_excluded_from_workshop: false).pluck(:id, :phone_number, :security_token)
    parents.each do |_id, phone_number, security_token|
      @recipient_data[phone_number] = {}
      @recipient_data[phone_number]['RESPONSE_LINK'] = Rails.application.routes.url_helpers.edit_workshop_participation_url(
        st: security_token,
        wid: @workshop_id
      )
    end
  end
end
