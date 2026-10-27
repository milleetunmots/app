class BlockedSendAttemptDecorator < BaseDecorator

  # Libellé de la tentative liée à une tâche de suivi : il ne dit rien du
  # contrôle déclenché, l'auteur voyant la tâche.
  def name
    "Envoi bloqué n°#{model.id}"
  end
end
