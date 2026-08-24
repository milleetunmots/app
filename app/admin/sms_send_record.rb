ActiveAdmin.register SmsSendRecord do
  menu parent: 'Gestion des envois', label: 'Envois comptabilisés', priority: 4

  actions :index # compteur technique : ni création, ni édition, ni suppression

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
end
