class SpotHit::DeleteRcsModelJob < ApplicationJob

  def perform(rcs_media_id)
    service = SpotHit::DeleteRcsModelService.new(rcs_media_id: rcs_media_id).call
    Rollbar.error('SpotHit::DeleteRcsModelJob', errors: service.errors) if service.errors.any?
  end
end
