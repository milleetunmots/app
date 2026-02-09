ActiveAdmin.register_page 'Réglages' do
  menu false

  content do
    render partial: 'admin/admin_user_can_send_automatic_sms_parameters/modal'
    panel 'Paramètres des rendez-vous' do
      div style: 'display: flex; align-items: center;' do
        i class: 'far fa-check-circle', style: 'margin-right: 8px; color: #555; font-size: 20px;'
        if current_active_admin_user.can_send_automatic_sms
          span "Toutes les familles reçoivent un SMS automatique de prise de RDV avant chaque session d'appel.", style: 'margin-right: 30px;'
        else
          span style: 'margin-right: 30px;' do
            b 'Aucune'
            span " famille ne reçoit de SMS automatique de prise de RDV avant chaque session d'appel."
          end
        end
        if current_active_admin_user.can_send_automatic_sms
          a 'Désactiver les SMS de RDV', href: '#', class: 'button'
        else
          a 'Activer les SMS de RDV', href: '#', class: 'button'
        end
      end
    end
  end
end
