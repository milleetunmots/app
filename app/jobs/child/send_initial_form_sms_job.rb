class Child::SendInitialFormSmsJob < ApplicationJob
  # Second argument : texte des jobs programmés avant le passage aux trios, ignoré (valeurs recalculées à l'envoi).
  def perform(parent1_id, _legacy_message = nil)
    parent = Parent.find(parent1_id)
    child_support = parent.current_child&.child_support
    return if child_support.nil?
    return if child_support.enrollment_reasons.any?

    service = Child::ProgramRegistrationMessagesService.new(parent).send_questionnaire(at: Time.zone.now)
    return if service.errors.blank?

    # sans cette remontée, une panne du fournisseur (réponse non-JSON) se solde
    # par un SMS perdu en silence : le job n'exploite pas `errors` autrement
    Rollbar.error("Child::SendInitialFormSmsJob : #{service.errors}", parent_id: parent1_id)
  end
end