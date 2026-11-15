class AddKeyToMedia < ActiveRecord::Migration[7.0]

  def change
    # Clé fixe d'un trio de message automatique, posée par la tâche rake : le code la lit, l'équipe ne la modifie pas.
    add_column :media, :key, :string
    add_index :media, :key, unique: true, where: 'key IS NOT NULL'
  end
end
