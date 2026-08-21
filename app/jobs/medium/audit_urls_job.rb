require 'sidekiq-scheduler'

# Balayage périodique de la médiathèque : les urls non conformes enregistrées
# avant l'activation du filtre (ou pendant la phase de surveillance) ne se
# découvriraient sinon qu'au moment où quelqu'un réédite le média.
class Medium::AuditUrlsJob < ApplicationJob

  def perform
    refused = Medium.refused_by_url_filter
    return if refused.empty?

    Task::CreateAutomaticTaskService.new(
      title: "Médias dont l'url serait refusée par le filtre - prévenir admins",
      description: description_for(refused)
    ).call
  end

  private

  def description_for(media)
    lines = media.map { |medium| "##{medium.id} — #{medium.type} — #{medium.name} — #{medium.url}" }

    "#{media.count} média(s) à corriger (url à remplacer, ou domaine à ajouter aux patterns autorisés) :<br>#{lines.join('<br>')}"
  end
end
