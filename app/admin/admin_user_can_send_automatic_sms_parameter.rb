ActiveAdmin.register_page 'Réglages' do
  menu false

  content do
    render partial: 'admin/admin_user_can_send_automatic_sms_parameters/modal'
    render partial: 'admin/admin_user_can_send_automatic_sms_parameters/settings_panel', locals: { on_dashboard: false }
  end

  page_action :toggle_automatic_sms, method: :post do
    current_admin_user.update!(can_send_automatic_sms: !current_admin_user.can_send_automatic_sms)
    if current_admin_user.can_send_automatic_sms
      redirect_to admin_reglages_path
    else
      redirect_to admin_reglages_path, notice: 'SMS de RDV désactivés'
    end
  end
end
