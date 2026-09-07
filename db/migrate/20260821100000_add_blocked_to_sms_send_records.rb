class AddBlockedToSmsSendRecords < ActiveRecord::Migration[7.0]

  def change
    add_column :sms_send_records, :blocked, :boolean, default: false, null: false

    # Toutes les lectures du quota deviennent « somme des destinataires de cet
    # utilisateur, non annulés, depuis tel instant » : `blocked` s'insère entre
    # les deux colonnes existantes pour que l'égalité précède la plage sur
    # created_at, sinon l'index ne couvre plus le filtre temporel. Le préfixe
    # `admin_user_id` reste utilisable seul.
    # Nom explicite : le nom généré dépasserait les 63 caractères de PostgreSQL.
    remove_index :sms_send_records, %i[admin_user_id created_at]
    add_index :sms_send_records, %i[admin_user_id blocked created_at],
              name: 'index_sms_send_records_on_admin_user_blocked_created_at'
  end
end
