# == Schema Information
#
# Table name: sms_send_records
#
#  id               :bigint           not null, primary key
#  recipients_count :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  admin_user_id    :bigint           not null
#
# Indexes
#
#  index_sms_send_records_on_admin_user_id_and_created_at  (admin_user_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#
# Consommation du quota d'envoi Spot-Hit : une ligne = un envoi manuel accepté
# par le provider, avec le nombre de destinataires réellement transmis.
class SmsSendRecord < ApplicationRecord

  HOURLY_WINDOW = 1.hour
  DAILY_WINDOW = 24.hours

  belongs_to :admin_user

  validates :recipients_count, numericality: { only_integer: true, greater_than: 0 }

  # Fenêtres ancrées sur created_at, c'est-à-dire l'instant de la programmation
  # et jamais la date d'envoi planifiée : un envoi programmé pour dans trois
  # jours consomme le quota immédiatement, et rien ne se réinitialise à minuit.
  scope :since, ->(window) { where(created_at: window.ago..) }
end
