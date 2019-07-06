class ApplicationController < ActionController::Base
  def status
    render plain: 'OK', status: 200
  end

  protected

  def user_for_paper_trail
    admin_user_signed_in? ? [current_admin_user.id, current_admin_user.email].join(':') : '0:anonymous'
  end
end
