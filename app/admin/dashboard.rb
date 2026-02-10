ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    render partial: 'admin/admin_user_can_send_automatic_sms_parameters/settings_panel', locals: { on_dashboard: true } if current_active_admin_user.user_role.in?(%w[caller animator])
    render 'tasks'
    render 'paper_trail'
  end

end
