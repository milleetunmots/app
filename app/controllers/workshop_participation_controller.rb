class WorkshopParticipationController < ApplicationController

  before_action do
    @workshop_participation = Event.workshop_participations.where(
      related_id: params[:parent_id],
      workshop_id: params[:workshop_id]
    ).first
  end

  def edit
    @workshop_participation_action_path = update_workshop_participation_path(
      parent_id: @workshop_participation.related_id,
      workshop_id: @workshop_participation.workshop_id
    )
  end

  def update
    @workshop_participation.attributes = params.require(:workshop_participation).permit(:parent_response)
    if @workshop_participation.save(validate: false)
      redirect_to updated_workshop_participation_path
    else
      render action: :edit
    end
  end
end
