class ApplicationController < ActionController::Base
  # Actions ActiveAdmin en GET ouvertes pendant une simulation de connexion. Plusieurs
  # member_action et collection_action répondent en GET avec effet de bord (Group#program,
  # Child#quit_group, Video#import_from_airtable…) et certaines ne vérifient aucun droit :
  # la seule liste sûre est une liste blanche.
  IMPERSONATION_ACTIVE_ADMIN_ACTIONS = %w[
    index show edit history
    parents search_eligible_parents preview_available_support_modules read_content
    send_message_to_parent1 send_message_to_parent2
  ].freeze

  before_action :authenticate_admin_user!

  impersonates :admin_user, with: ->(id) { AdminUser.account_not_disabled.find_by(id: id) }
  before_action :set_impersonation_context
  before_action :enforce_read_only_impersonation

  def access_denied(exception)
    redirect_to admin_children_url, alert: exception.message
  end

  around_action :set_time_zone

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

  def current_ability
    @current_ability ||= Ability.new(current_admin_user)
  end


  protected

  def user_for_paper_trail
    admin_user_signed_in? ? [true_admin_user.id, true_admin_user.email].join(':') : '0:anonymous'
  end

  # Revérifié à chaque requête : un compte désactivé ou un super admin rétrogradé en cours
  # de simulation y met fin.
  def set_impersonation_context
    return unless session[:impersonated_admin_user_id]

    impersonated = current_admin_user
    if impersonated == true_admin_user || !Ability.new(true_admin_user, read_only: false).can?(:impersonate, impersonated)
      stop_impersonating_admin_user
      return
    end

    Current.impersonator = true_admin_user
  end

  def enforce_read_only_impersonation
    return unless Current.impersonating?
    return if (request.get? || request.head?) && impersonation_allows_action?

    message = "Lecture seule : vous consultez la base famille en tant que #{current_admin_user.name}."
    if request.xhr? || !request.format.html?
      render json: { error: message, impersonation: true }, status: :forbidden
    else
      redirect_back fallback_location: admin_root_path, alert: message
    end
  end

  def impersonation_allows_action?
    !is_a?(ActiveAdmin::ResourceController) || action_name.in?(IMPERSONATION_ACTIVE_ADMIN_ACTIONS)
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  private

  def set_time_zone(&block)
    zone = ActiveSupport::TimeZone[cookies[:time_zone]] if cookies[:time_zone]
    Time.use_zone(zone || 'Europe/Paris', &block)
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
