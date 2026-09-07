class Workshop::ProgramWorkshopInvitationService < ProgramMessageService

  def format_data_for_spot_hit(_rcs = false)
    @recipient_data = {}
    parents = Parent.kept.where(id: @parent_ids, is_excluded_from_workshop: false).pluck(:id, :security_token)
    parents.each do |id, security_token|
      @recipient_data[id] = {}
      @recipient_data[id]['RESPONSE_LINK'] = Rails.application.routes.url_helpers.edit_workshop_participation_url(
        st: security_token,
        wid: @workshop_id
      )
    end
  end
end
