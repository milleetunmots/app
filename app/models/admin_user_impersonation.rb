# == Schema Information
#
# Table name: admin_user_impersonations
#
#  id          :bigint           not null, primary key
#  ended_at    :datetime
#  started_at  :datetime         not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  operator_id :bigint           not null
#  target_id   :bigint           not null
#
# Indexes
#
#  index_admin_user_impersonations_on_operator_id  (operator_id)
#  index_admin_user_impersonations_on_target_id    (target_id)
#
# Foreign Keys
#
#  fk_rails_...  (operator_id => admin_users.id)
#  fk_rails_...  (target_id => admin_users.id)
#
class AdminUserImpersonation < ApplicationRecord

  belongs_to :operator, class_name: 'AdminUser'
  belongs_to :target, class_name: 'AdminUser'

  validates :started_at, presence: true

  scope :ongoing, -> { where(ended_at: nil) }

  # Idempotent : la fin peut être demandée par plusieurs chemins (bouton,
  # déconnexion, cible désactivée) sans écraser la première.
  def finish!
    update!(ended_at: Time.current) if ended_at.nil?
  end
end
