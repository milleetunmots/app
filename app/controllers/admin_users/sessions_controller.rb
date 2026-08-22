module AdminUsers
  class SessionsController < ActiveAdmin::Devise::SessionsController

    def create
      self.resource = warden.authenticate!(auth_options)
      return sign_in_without_second_factor unless resource.two_factor_enabled?

      # warden.authenticate! a déjà ouvert la session : on la referme avant
      # d'écrire l'état « en attente ». Le logout scopé ne vide que les clés
      # du scope :admin_user et efface le cookie « se souvenir de moi ».
      sign_out(resource)

      if resource.phone_number.blank?
        redirect_to new_admin_user_session_path, alert: TwoFactorMessages::MISSING_PHONE_NUMBER
        return
      end

      # Pas de clé « remember_me » : la spec impose un code à chaque connexion,
      # sans navigateur de confiance. Un compte sans second facteur garde le
      # comportement « se souvenir de moi » habituel de Devise.
      session[:pending_two_factor] = { 'id' => resource.id, 'at' => Time.current.to_i }
      send_two_factor_code(resource)
      redirect_to admin_two_factor_path
    end

    private

    def sign_in_without_second_factor
      # Une tentative précédente sur un compte protégé a pu laisser un état en
      # attente : il n'a plus lieu d'être une fois une session ouverte.
      session.delete(:pending_two_factor)
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      respond_with resource, location: after_sign_in_path_for(resource)
    end

    # Une seule règle d'envoi, ici comme au renvoi : un code par minute et par
    # compte. Re-poster le formulaire de login ne doit pas être un moyen de
    # multiplier les SMS. Le code déjà envoyé reste valable dix minutes.
    def send_two_factor_code(admin_user)
      unless admin_user.otp_resendable?
        flash[:alert] = TwoFactorMessages::RESEND_TOO_SOON
        return
      end

      service = admin_user.send_otp_by_sms
      return if service.errors.empty?

      report_send_failure(admin_user, service.errors)
    rescue StandardError => e
      # HTTP.post n'est rescué nulle part dans SendMessageService : sans cette
      # garde, une coupure réseau transformerait le POST de login en 500.
      report_send_failure(admin_user, [e.class.name])
    end

    def report_send_failure(admin_user, errors)
      Rollbar.error("2FA : échec de l'envoi du code", admin_user_id: admin_user.id, errors: errors)
      flash[:alert] = TwoFactorMessages::SEND_FAILED
    end
  end
end
