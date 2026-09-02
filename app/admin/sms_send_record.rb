ActiveAdmin.register SmsSendRecord do
  menu parent: 'Gestion des envois', label: 'Envois comptabilisés', priority: 4

  actions :index, :show # compteur technique : ni création, ni édition, ni suppression

  includes :admin_user

  config.sort_order = 'created_at_desc'

  filter :admin_user
  filter :blocked
  filter :created_at

  index do
    id_column
    column :created_at
    column :admin_user
    column :recipients_count
    # Envoi finalement non parti : la ligne subsiste pour la trace, mais ne
    # consomme plus le quota de l'utilisateur.
    column :blocked
  end

  # Cible du lien porté par l'alerte Slack de dépassement de quota
  # (cf. SmsSendRecord::QuotaGuard#blocked_record_line).
  show do
    attributes_table do
      row :created_at
      row :admin_user
      row :recipients_count
      row :blocked
      row :updated_at
    end
  end
end
