module ActiveAdmin::AdminUsersHelper

  def admin_user_role_select_collection
    AdminUser::ROLES.map do |v|
      [
        AdminUser.human_attribute_name("user_role.#{v}"),
        v
      ]
    end
  end

  def admin_user_in_params
    AdminUser.find(params[:id]) if params[:id]
  end

  def admin_user_select_collection
    AdminUser.order(:id).pluck(:name)
  end
end
