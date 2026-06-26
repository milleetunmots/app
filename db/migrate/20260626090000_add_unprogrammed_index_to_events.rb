class AddUnprogrammedIndexToEvents < ActiveRecord::Migration[7.0]
  # Index partiel pour Events::TextMessage::RemoveUnprogrammedJob.
  # La requête `type = 'Events::TextMessage' AND originated_by_app AND spot_hit_status = 0`
  # provoquait un Parallel Seq Scan sur ~3,3M lignes (l'index sur `type` n'est pas
  # sélectif puisque presque tous les events sont des TextMessage).
  # L'index ne contient que les lignes concernées et est ordonné par `id`, ce qui
  # colle exactement au `find_each` (WHERE ... AND id > ? ORDER BY id LIMIT 1000).
  disable_ddl_transaction!

  def change
    add_index :events, :id,
              name: 'index_events_on_unprogrammed',
              where: "type = 'Events::TextMessage' AND originated_by_app AND spot_hit_status = 0",
              algorithm: :concurrently
  end
end
