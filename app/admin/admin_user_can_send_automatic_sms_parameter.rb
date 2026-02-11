ActiveAdmin.register_page 'Réglages' do
  menu false

  content do
    render partial: 'admin/admin_user_can_send_automatic_sms_parameters/modal'
    render partial: 'admin/admin_user_can_send_automatic_sms_parameters/settings_panel', locals: { on_dashboard: false }
  end

  page_action :toggle_automatic_sms, method: :post do
    current_admin_user.update!(can_send_automatic_sms: !current_admin_user.can_send_automatic_sms)
    notice = current_admin_user.can_send_automatic_sms ? 'SMS de RDV activés' : 'SMS de RDV désactivés'
    redirect_to admin_reglages_path, notice: notice
  end
end
