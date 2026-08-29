module AdminUsers
  class SessionsController < ActiveAdmin::Devise::SessionsController

    skip_before_action :authenticate_admin_user!
    skip_before_action :set_paper_trail_whodunnit

    def create
      # Le premier facteur est validé sans persister de session Warden. On
      # évite ainsi le sign_out intermédiaire qui déclenchait forget_me! et
      # révoquait les cookies « se souvenir de moi » de tous les navigateurs.
      self.resource = warden.authenticate!(auth_options.merge(store: false))
      return sign_in_without_second_factor unless resource.two_factor_enabled?

      if resource.phone_number.blank?
        redirect_to new_admin_user_session_path, alert: TwoFactorMessages::MISSING_PHONE_NUMBER
        return
      end

      session[:pending_two_factor] = pending_state_for(resource)
      send_two_factor_code(resource)
      redirect_to admin_two_factor_path
    end

    private

    # La case « se souvenir de moi » vaut pour les deux facteurs : on la
    # transporte jusqu'à la validation du code, qui posera le cookie de sept
    # jours. L'authentification du premier facteur utilise store: false, donc
    # rien n'est mémorisé tant que le code n'est pas validé.
    def pending_state_for(admin_user)
      {
        'id' => admin_user.id,
        'at' => Time.current.to_i,
        'remember_me' => params.dig(:admin_user, :remember_me).in?(['1', 'true', true])
      }
    end

    def sign_in_without_second_factor
      # Une tentative précédente sur un compte protégé a pu laisser un état en
      # attente : il n'a plus lieu d'être une fois une session ouverte.
      session.delete(:pending_two_factor)
      set_flash_message!(:notice, :signed_in)
      # Warden connaît déjà la ressource issue de l'authentification store:false.
      # force est nécessaire pour la sérialiser réellement dans la session.
      sign_in(resource_name, resource, force: true)
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
