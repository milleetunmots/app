class CreateSmsSendRecords < ActiveRecord::Migration[7.0]

  def change
    create_table :sms_send_records do |t|
      t.references :admin_user, null: false, foreign_key: true, index: false
      t.integer :recipients_count, null: false

      t.timestamps
    end

    # Toutes les lectures sont « somme des destinataires de cet utilisateur
    # depuis tel instant » : l'index composite couvre les deux fenêtres, et son
    # préfixe couvre les recherches par utilisateur seul — d'où `index: false`
    # sur la référence, qui serait redondante.
    add_index :sms_send_records, %i[admin_user_id created_at]
  end
end
