# Contexte propre à la requête en cours, remis à zéro entre deux requêtes.
class Current < ActiveSupport::CurrentAttributes

  # Super admin qui consulte l'admin à la place d'un autre compte (« Se connecter en tant que »).
  # Renseigné par ApplicationController ; Ability et les décorateurs passent alors en lecture seule.
  attribute :impersonator

  def impersonating?
    impersonator.present?
  end
end
