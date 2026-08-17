class Child::SendInitialFormSmsJob < ApplicationJob
  def perform(parent1_id, message)
    child_support = Parent.find(parent1_id).current_child&.child_support
    return if child_support.nil?
    return if child_support.enrollment_reasons.any?

    service = SpotHit::SendSmsService.new([parent1_id], Time.zone.now.to_i, message).call
    return if service.errors.blank?

    # sans cette remontée, une panne du fournisseur (réponse non-JSON) se solde
    # par un SMS perdu en silence : le job n'exploite pas `errors` autrement
    Rollbar.error("Child::SendInitialFormSmsJob : #{service.errors}", parent_id: parent1_id)
  end
end