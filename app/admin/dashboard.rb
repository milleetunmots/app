ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    columns do
      column do
        panel I18n.t("active_admin.paper_trail.dashboard.title") do
          table_for PaperTrail::Version.order('id desc').limit(20) do
            column I18n.t("active_admin.paper_trail.dashboard.columns.item") do |v|
              if v.item
                v.item.decorate.admin_link
              end
            end
            column I18n.t("active_admin.paper_trail.dashboard.columns.type") do |v|
              v.item_type.constantize.model_name.human
            end
            column I18n.t("active_admin.paper_trail.dashboard.columns.modified_at") do |v|
              l v.created_at, format: :short
            end
            column I18n.t("active_admin.paper_trail.dashboard.columns.whodunnit") do |v|
              id, email = v.whodunnit.split(':')
              if admin = AdminUser.where(id: id).first
                auto_link admin
              else
                email
              end
            end
          end
        end
      end
    end
  end

end
