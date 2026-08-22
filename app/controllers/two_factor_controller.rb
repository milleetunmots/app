class TwoFactorController < ApplicationController

  include ActiveAdmin::Devise::Controller

  skip_before_action :authenticate_admin_user!
  before_action :load_pending_admin_user

  def show; end

  def verify
    case @admin_user.verify_otp(params[:otp_code])
    when :ok
      complete_sign_in
    when :invalid
      render_error('Code incorrect.')
    when :expired
      render_error('Ce code a expiré. Demandez-en un nouveau.')
    when :too_many_attempts
      render_error('Trop de tentatives. Demandez un nouveau code.')
    else
      render_error('Aucun code en cours. Demandez un nouveau code.')
    end
  end

  def resend
    # Le numéro a pu être retiré par un super_admin pendant que la session en
    # attente était ouverte : sans cette garde, l'envoi lèverait une exception.
    if @admin_user.phone_number.blank?
      session.delete(:pending_two_factor)
      redirect_to new_admin_user_session_path, alert: TwoFactorMessages::MISSING_PHONE_NUMBER
      return
    end

    unless @admin_user.otp_resendable?
      redirect_to admin_two_factor_path, alert: TwoFactorMessages::RESEND_TOO_SOON
      return
    end

    service = @admin_user.send_otp_by_sms

    if service.errors.empty?
      refresh_pending_window
      redirect_to admin_two_factor_path, notice: 'Un nouveau code vient de vous être envoyé.'
    else
      Rollbar.error("2FA : échec de l'envoi du code", admin_user_id: @admin_user.id, errors: service.errors)
      redirect_to admin_two_factor_path, alert: "L'envoi du code a échoué. Réessayez dans un instant."
    end
  end

  private

  def pending_two_factor
    session[:pending_two_factor]
  end

  def load_pending_admin_user
    pending = pending_two_factor
    @admin_user = AdminUser.find_by(id: pending['id']) if pending.present? && pending_fresh?(pending)
    return if @admin_user

    session.delete(:pending_two_factor)
    redirect_to new_admin_user_session_path, alert: 'Votre session de connexion a expiré. Recommencez.'
  end

  def pending_fresh?(pending)
    Time.zone.at(pending['at'].to_i) > AdminUser::OTP_VALIDITY.ago
  end

  # Le code fraîchement envoyé vit dix minutes : la session en attente, datée du
  # login, ne doit pas expirer avant lui sur un « votre session a expiré » qui
  # n'expliquerait rien.
  def refresh_pending_window
    session[:pending_two_factor] = pending_two_factor.merge('at' => Time.current.to_i)
  end

  # Aucun cookie « se souvenir de moi » n'est posé ici : la spec impose un code
  # à chaque connexion, sans navigateur de confiance. Un code validé n'achète
  # donc pas quatorze jours d'accès sans second facteur.
  def complete_sign_in
    session.delete(:pending_two_factor)
    sign_in(:admin_user, @admin_user)
    redirect_to after_sign_in_path_for(@admin_user), notice: 'Connexion réussie.'
  end

  def render_error(message)
    flash.now[:alert] = message
    render :show, status: :unprocessable_entity
  end
end
