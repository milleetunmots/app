module ActiveAdmin::BlockedSendAttemptsHelper

  # La whitelist est systématique : l'admin doit savoir, avant de cliquer, que sa
  # relance engage tous les envois à venir et pas seulement celui qu'il consulte.
  def blocked_send_attempt_relaunch_warning(attempt)
    if BlockedSendAttempt::DetectedValuesWhitelister::MATCH_TYPE_BY_KIND.key?(attempt.kind)
      'La relance ajoute les valeurs détectées aux patterns autorisés : les prochains envois qui les contiennent ne seront plus bloqués.'
    else
      'La relance ne concerne que cet envoi : le terme détecté restera interdit pour les prochains.'
    end
  end
end
