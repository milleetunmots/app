class AddAdminUserToBlockedSendAttempts < ActiveRecord::Migration[7.0]

  def change
    # Nullable : les envois automatiques n'ont pas d'auteur, et les tentatives
    # antérieures restent sans auteur (aucun backfill possible).
    add_reference :blocked_send_attempts, :admin_user, foreign_key: true, null: true
  end
end
