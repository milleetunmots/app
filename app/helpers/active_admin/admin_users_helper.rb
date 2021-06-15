module ActiveAdmin::AdminUsersHelper

  def admin_user_role_select_collection
    AdminUser::ROLES.map do |v|
      [
        AdminUser.human_attribute_name("user_role.#{v}"),
        v
      ]
    end
  end
end
