class ApplicationController < ActionController::Base
  before_action :authenticate_admin_user!
  before_action :set_time_zone

  def access_denied(exception)
    redirect_to admin_children_url, alert: exception.message
  end

  def status
    checks = {
      db: check_database,
      sidekiq: check_sidekiq
    }

    if checks.values.all?
      render json: { status: 'OK', checks: checks }, status: :ok
    else
      render json: { status: 'KO', checks: checks }, status: :service_unavailable
    end
  end

  protected

  def user_for_paper_trail
    admin_user_signed_in? ? [current_admin_user.id, current_admin_user.email].join(':') : '0:anonymous'
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  private

  def set_time_zone
    if time_zone = cookies[:time_zone]
      Time.zone = ActiveSupport::TimeZone[time_zone]
    end
  end

  def check_database
    ActiveRecord::Base.connection.active?
  rescue
    false
  end

  def check_sidekiq
    Sidekiq::ProcessSet.new.size > 0
  rescue
    false
  end
end
