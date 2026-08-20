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
      # TODO: brancher ici l'alerting Slack des blocages — c'est l'unique chemin
      # par lequel un envoi est refusé pour dépassement de plafond.
      @record = SmsSendRecord.create!(admin_user_id: @admin_user.id, recipients_count: @recipients_count) unless exceeds_limits?
    end

    @record.present?
  end

  # Finalement rien n'est parti (erreur API Spot-Hit, message bloqué par le
  # BlockedSendAttempt::SendGuard) : le quota réservé est rendu, l'utilisateur
  # ne doit pas être pénalisé pour un envoi qui n'a pas eu lieu.
  def release!
    @record&.destroy
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
  def exceeds_limits?
    consumed(SmsSendRecord::HOURLY_WINDOW) + @recipients_count > @admin_user.sms_hourly_recipients_limit ||
      consumed(SmsSendRecord::DAILY_WINDOW) + @recipients_count > @admin_user.sms_daily_recipients_limit
  end

  def consumed(window)
    @admin_user.sms_send_records.since(window).sum(:recipients_count)
  end
end
