# == Schema Information
#
# Table name: sms_send_records
#
#  id               :bigint           not null, primary key
#  blocked          :boolean          default(FALSE), not null
#  recipients_count :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  admin_user_id    :bigint           not null
#
# Indexes
#
#  index_sms_send_records_on_admin_user_blocked_created_at  (admin_user_id,blocked,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#
class SmsSendRecord < ApplicationRecord

  HOURLY_WINDOW = 1.hour
  DAILY_WINDOW = 24.hours

  belongs_to :admin_user

  validates :recipients_count, numericality: { only_integer: true, greater_than: 0 }

  # Fenêtres ancrées sur created_at, c'est-à-dire l'instant de la programmation
  # et jamais la date d'envoi planifiée : un envoi programmé pour dans trois
  # jours consomme le quota immédiatement, et rien ne se réinitialise à minuit.
  scope :since, ->(window) { where(created_at: window.ago..) }

  # Un envoi finalement non parti (erreur API Spot-Hit, message retenu par le
  # BlockedSendAttempt::SendGuard) est marqué plutôt que supprimé : la trace de
  # la tentative reste consultable, mais la ligne ne consomme plus le quota.
  scope :not_blocked, -> { where(blocked: false) }
end
