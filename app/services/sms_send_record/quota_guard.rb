# Garde anti-fraude des envois Spot-Hit déclenchés à la main depuis l'admin : un
# AdminUser ne peut toucher qu'un nombre limité de destinataires sur des
# fenêtres glissantes. Le blocage est total — si l'envoi complet ne tient pas
# dans le quota restant, aucun message ne part.
class SmsSendRecord::QuotaGuard

  # Volontairement identique pour les deux fenêtres : l'utilisateur n'a pas à
  # savoir laquelle est atteinte, il doit contacter un admin.
  QUOTA_EXCEEDED_MESSAGE = "Vous avez atteint la limite d'envoi de messages. Aucun message n'a pu être envoyé. Contactez un admin.".freeze

  def initialize(admin_user, recipients_count)
    @admin_user = admin_user
    @recipients_count = recipients_count.to_i
  end

  # Réserve le quota AVANT l'appel au provider, et renvoie false sans rien
  # écrire si l'un des deux plafonds serait dépassé. La vérification et
  # l'écriture sont faites sous verrou de la ligne admin_users : deux envois
  # simultanés du même utilisateur ne peuvent pas passer tous les deux.
  def reserve!
    return true if exempt? || @recipients_count.zero?

    SmsSendRecord.transaction do
      # `AdminUser.lock.find` (SELECT … FOR UPDATE) plutôt que `with_lock` /
      # `lock!` : ces derniers rechargent l'objet et lèvent « Locking a record
      # with unpersisted changes is not supported » si l'AdminUser porte des
      # attributs sales, ce qui peut arriver avec le trackable de Devise.
      AdminUser.lock.find(@admin_user.id)
      @record = SmsSendRecord.create!(admin_user_id: @admin_user.id, recipients_count: @recipients_count, blocked: false) unless exceeds_limits?
    end

    return true if @record.present?

    # Hors transaction, verrou relâché : `Rollbar.warning` est synchrone
    # (`use_async` non activé), alerter sous le SELECT … FOR UPDATE retiendrait
    # le verrou de la ligne admin_users pendant l'aller-retour HTTP.
    report_block!
    false
  end

  # Finalement rien n'est parti (erreur API Spot-Hit, message bloqué par le
  # BlockedSendAttempt::SendGuard) : le quota réservé est rendu, l'utilisateur
  # ne doit pas être pénalisé pour un envoi qui n'a pas eu lieu. La ligne est
  # marquée et non supprimée, pour garder la trace de la tentative — c'est le
  # scope `not_blocked` qui l'exclut du décompte.
  def mark_blocked!
    @record&.update!(blocked: true)
    @record = nil
  end

  def error_message
    QUOTA_EXCEEDED_MESSAGE
  end

  private

  # Contrôle opt-in : sans utilisateur à l'origine (crons, jobs, webhooks,
  # messages de modules) aucun plafond ne s'applique. Les super_admin non plus,
  # ils doivent pouvoir débloquer une situation sans être freinés.
  def exempt?
    @admin_user.nil? || @admin_user.admin?
  end

  # Comparaison stricte : un envoi qui atteint exactement le plafond passe.
  # Les deux fenêtres sont évaluées sans court-circuit : le `||` d'origine
  # laissait la consommation journalière non calculée dès que l'horaire sautait,
  # et elle manquerait à l'alerte.
  def exceeds_limits?
    @exceeded_windows = []
    @exceeded_windows << 'horaire' if consumed(SmsSendRecord::HOURLY_WINDOW) + @recipients_count > @admin_user.sms_hourly_recipients_limit
    @exceeded_windows << 'journalier' if consumed(SmsSendRecord::DAILY_WINDOW) + @recipients_count > @admin_user.sms_daily_recipients_limit
    @exceeded_windows.any?
  end

  # Mémoïsé pour que l'alerte porte les valeurs sur lesquelles la décision a été
  # prise, et non des valeurs relues après relâchement du verrou.
  def consumed(window)
    @consumed ||= {}
    @consumed[window] ||= @admin_user.sms_send_records.not_blocked.since(window).sum(:recipients_count)
  end

  # Signal anti-fraude à destination de l'équipe tech, relayé dans Slack par
  # l'intégration Rollbar. L'email est dans le libellé et non dans le payload
  # pour que Rollbar crée un item par utilisatrice : un libellé constant ne
  # formerait qu'un seul item, et Slack ne serait notifié qu'aux 1er, 10e et
  # 100e blocages toutes utilisatrices confondues. Contrairement au message
  # affiché à l'utilisatrice, le payload peut nommer la fenêtre franchie.
  def report_block!
    Rollbar.warning(
      "SmsSendRecord::QuotaGuard : envoi bloqué — #{@admin_user.email}",
      admin_user_id: @admin_user.id,
      recipients_count: @recipients_count,
      exceeded_windows: @exceeded_windows,
      consumed_hourly: consumed(SmsSendRecord::HOURLY_WINDOW),
      consumed_daily: consumed(SmsSendRecord::DAILY_WINDOW),
      hourly_limit: @admin_user.sms_hourly_recipients_limit,
      daily_limit: @admin_user.sms_daily_recipients_limit
    )
  end
end
