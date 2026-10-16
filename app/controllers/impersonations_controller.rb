class ImpersonationsController < ApplicationController

  def create
    return redirect_back_with_alert(t('impersonation.errors.already_impersonating')) if impersonating?

    target = AdminUser.find(params[:admin_user_id])
    service = AdminUser::StartImpersonationService.new(operator: true_admin_user, target: target).call
    return redirect_back_with_alert(service.errors.pluck(:message).join(' - ')) unless service.errors.empty?

    session[Impersonation::SESSION_KEY] = service.impersonation.id
    redirect_to admin_root_path, notice: t('impersonation.started', name: target.name)
  end

  def destroy
    end_impersonation
    redirect_to admin_root_path
  end

  private

  def redirect_back_with_alert(message)
    redirect_back fallback_location: admin_root_path, alert: message
  end
end
