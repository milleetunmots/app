# « Se connecter en tant que » : un super admin consulte l'admin avec les droits et le
# périmètre d'un autre compte, sans pouvoir rien modifier. Le second facteur est celui du
# super admin : pretender ne fait aucun sign_in, la session Warden reste la sienne.
class ImpersonationsController < ApplicationController

  # Quitter la simulation est la seule écriture permise pendant celle-ci
  skip_before_action :enforce_read_only_impersonation, only: :destroy

  def create
    admin_user = AdminUser.find(params[:admin_user_id])

    unless Ability.new(true_admin_user, read_only: false).can?(:impersonate, admin_user)
      redirect_back fallback_location: admin_admin_user_path(admin_user),
                    alert: 'Vous ne pouvez pas vous connecter en tant que cet utilisateur.'
      return
    end

    impersonate_admin_user(admin_user)
    Rails.logger.info("[impersonation] start impersonator_id=#{true_admin_user.id} impersonated_id=#{admin_user.id}")
    redirect_to admin_root_path, notice: "Vous consultez la base famille en tant que #{admin_user.name}, en lecture seule."
  end

  def destroy
    impersonated = current_admin_user
    stop_impersonating_admin_user
    Rails.logger.info("[impersonation] stop impersonator_id=#{true_admin_user.id} impersonated_id=#{impersonated.id}")
    redirect_to admin_admin_user_path(impersonated), notice: 'Vous avez quitté la simulation.'
  end
end
