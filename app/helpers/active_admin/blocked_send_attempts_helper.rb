module ActiveAdmin::BlockedSendAttemptsHelper

  # La session est stockée en cookie (4 Ko) : un envoi de masse peut whitelister
  # des dizaines de valeurs, et les lister toutes dans le flash ferait échouer la
  # redirection sur un CookieOverflow — après que le message est parti.
  NOTICE_VALUES_LIMIT = 5

  # La whitelist est systématique : l'admin doit savoir, avant de cliquer, que sa
  # relance engage tous les envois à venir et pas seulement celui qu'il consulte.
  def blocked_send_attempt_relaunch_warning(attempt)
    if BlockedSendAttempt::DetectedValuesWhitelister::MATCH_TYPE_BY_KIND.key?(attempt.kind)
      'La relance ajoute les valeurs détectées aux patterns autorisés : les prochains envois qui les contiennent ne seront plus bloqués.'
    else
      'La relance ne concerne que cet envoi : le terme détecté restera interdit pour les prochains.'
    end
  end

  def blocked_send_attempt_relaunch_notice(whitelisted_values)
    return "L'envoi a été relancé." if whitelisted_values.empty?

    listed = whitelisted_values.first(NOTICE_VALUES_LIMIT).to_sentence
    extra = whitelisted_values.size - NOTICE_VALUES_LIMIT
    listed += " et #{extra} autres" if extra.positive?
    "L'envoi a été relancé. Valeurs ajoutées aux patterns autorisés : #{listed}."
  end
end
