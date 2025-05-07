class WorkshopParticipationController < ApplicationController
  skip_before_action :authenticate_admin_user!
  before_action :find_workshop_participation, only: %i[edit update]

  def edit
    @workshop_participation_action_path = update_workshop_participation_path(
      parent_id: @workshop_participation.related_id,
      workshop_id: @workshop_participation.workshop_id
    )
  end

  def update
    @workshop_participation.acceptation_date = Time.zone.today if workshop_participation_params[:parent_response] == "Oui"
    if @workshop_participation.update(workshop_participation_params)
      redirect_to updated_workshop_participation_path
    else
      render action: :edit
    end
  end

  private

  def workshop_participation_params
    params.require(:workshop_participation).permit(:parent_response)
  end

  def find_workshop_participation
    parent = Parent.find_by(security_token: params[:st])
    @workshop_participation = Event.workshop_participations.find_by(
      related_id: parent.id,
      workshop_id: params[:wid]
    )
    not_found and return if @workshop_participation.nil?
  end
end
