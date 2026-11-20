class AddAutomaticMessageKeyToEvents < ActiveRecord::Migration[7.0]

  def change
    # Clé du message automatique qui a produit le message : l'anti-doublon la compare, pas le texte, que l'équipe peut modifier.
    add_column :events, :automatic_message_key, :string
  end
end
