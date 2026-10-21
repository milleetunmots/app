module ActiveAdmin::AdminUsersHelper

  def admin_user_role_select_collection
    AdminUser::ROLES.map do |v|
      [
        AdminUser.human_attribute_name("user_role.#{v}"),
        v
      ]
    end
  end

  # Listes chargées en une requête (pluck, sans décorateur) pour des select2 fluides
  # kept_ids : valeurs actuelles d'un formulaire, gardées même désactivées pour ne pas être vidées à l'enregistrement
  def admin_user_select_collection(*kept_ids)
    AdminUser.account_not_disabled.or(AdminUser.where(id: kept_ids.compact)).order(:name).pluck(:name, :id)
  end

  def supporter_select_collection
    AdminUser.assignable_as_supporter.order(:name).pluck(:name, :id)
  end

  def admin_user_in_params
    AdminUser.find(params[:id]) if params[:id]
  end
end
