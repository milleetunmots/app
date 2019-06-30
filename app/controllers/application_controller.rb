class ApplicationController < ActionController::Base
  def status
    render plain: 'OK', status: 200
  end

  protected

  def user_for_paper_trail
    admin_user_signed_in? ? current_admin_user.try(:id) : 0
  end
end
