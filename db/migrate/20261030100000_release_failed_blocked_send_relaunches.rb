class ReleaseFailedBlockedSendRelaunches < ActiveRecord::Migration[7.0]

  # Une relance échouée laissait force_send à true sur une tentative restée à
  # traiter. force_send vaut désormais réservation : sans cette remise à zéro,
  # ces tentatives ne seraient plus ni relançables ni archivables.
  def up
    execute "UPDATE blocked_send_attempts SET force_send = false WHERE status = 'pending' AND force_send = true"
  end

  def down
    # Rien à restaurer : l'ancienne valeur ne servait qu'à la relance échouée.
  end
end
