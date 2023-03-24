class Workshop::ProgramWorkshopInvitationService < ProgramMessageService

  def format_data_for_spot_hit
    @recipient_data = {}
    parents = Parent.where(id: @parent_ids).pluck(:id, :security_code)
    parents.each do |id, security_code|
      @recipient_data[id.to_s] = {}
      @recipient_data[id.to_s]['RESPONSE_LINK'] = Rails.application.routes.url_helpers.edit_workshop_participation_url(
        parent_id: id,
        parent_security_code: security_code,
        workshop_id: @workshop_id
      )
    end
  end
end
