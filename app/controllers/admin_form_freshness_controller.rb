# Expose la date de dernière sauvegarde en base d'une fiche parent / enfant, pour que
# le formulaire d'édition détecte qu'il affiche un contenu périmé — pendant du
# mécanisme déjà en place sur la fiche de suivi (ChildSupportsController#updated_at).
class AdminFormFreshnessController < ApplicationController

  RECORD_CLASSES = { 'parent' => Parent, 'child' => Child, 'child_support' => ChildSupport }.freeze

  def updated_at
    record = RECORD_CLASSES.fetch(params[:record]).find_by(id: params[:id])
    not_found and return unless record

    render json: { updated_at: record.updated_at }
  end
end
