require 'rails_helper'

RSpec.describe 'Connexion avec double authentification', type: :request do
  let(:password) { '(Strass07591)' }
  let!(:admin_user) do
    FactoryBot.create(:admin_user,
                      user_role: 'super_admin',
                      password: password,
                      phone_number: '0612345678',
                      two_factor_enabled: true)
  end

  def post_login(email: admin_user.email, pwd: password, remember: false)
    post '/admin/login',
         params: { admin_user: { email: email, password: pwd, remember_me: remember ? '1' : '0' } }
  end

  describe 'compte sans 2FA' do
    let!(:simple_user) do
      FactoryBot.create(:admin_user, user_role: 'super_admin', password: password, two_factor_enabled: false)
    end

    it 'ouvre la session directement et n’envoie aucun SMS' do
      post '/admin/login', params: { admin_user: { email: simple_user.email, password: password } }

      get '/admin/children'
      expect(response).to have_http_status(:ok)
      expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
    end

    it 'purge l’état « en attente » laissé par une tentative précédente' do
      post_login

      post '/admin/login', params: { admin_user: { email: simple_user.email, password: password } }

      get '/admin/two_factor'
      expect(response).to redirect_to(new_admin_user_session_path)
    end
  end

  describe 'compte avec 2FA' do
    it 'n’ouvre pas la session et redirige vers la saisie du code' do
      post_login
      expect(response).to redirect_to('/admin/two_factor')

      get '/admin/children'
      expect(response).to redirect_to(new_admin_user_session_path)
    end

    it 'envoie un code au numéro du compte' do
      post_login

      expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
        .with { |request| request.body.include?(CGI.escape('+33612345678')) }
      expect(admin_user.reload.otp_code_digest).to be_present
    end

    it 'affiche le formulaire avec le numéro masqué' do
      post_login
      follow_redirect!

      expect(response.body).to include('•• •• •• •• 78')
      expect(response.body).not_to include(admin_user.phone_number)
    end

    it 'refuse un mot de passe invalide sans envoyer de code' do
      post_login(pwd: 'mauvais-mot-de-passe')

      expect(response).not_to redirect_to('/admin/two_factor')
      expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms')

      get '/admin/children'
      expect(response).to redirect_to(new_admin_user_session_path)
    end

    # Une limite d'envoi par compte, et non par chemin : re-poster le formulaire
    # de login ne doit pas être un moyen de faire pleuvoir les SMS.
    it 'ne renvoie pas de code sur une seconde tentative de connexion dans la minute' do
      post_login
      post_login

      expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms').once
      expect(response).to redirect_to('/admin/two_factor')
      follow_redirect!
      expect(response.body).to include('Patientez')

      get '/admin/children'
      expect(response).to redirect_to(new_admin_user_session_path)
    end

    it 'ne révoque pas les navigateurs déjà mémorisés pendant le premier facteur' do
      remembered_at = 1.day.ago
      admin_user.update!(remember_created_at: remembered_at)

      post_login

      expect(admin_user.reload.remember_created_at).to be_within(1.second).of(remembered_at)
    end
  end

  describe 'réinitialisation du mot de passe' do
    let(:new_password) { '(Bergamote4278)' }

    # sign_in_after_reset_password ouvrirait une session complète sur un compte
    # protégé, sans le moindre code : le second facteur serait contournable via
    # le lien « mot de passe oublié ».
    it 'n’ouvre pas de session sur un compte protégé par le second facteur' do
      token = admin_user.send(:set_reset_password_token)

      put '/admin/password',
          params: { admin_user: { reset_password_token: token,
                                  password: new_password,
                                  password_confirmation: new_password } }

      expect(admin_user.reload.valid_password?(new_password)).to be(true)

      get '/admin/children'
      expect(response).to redirect_to(new_admin_user_session_path)
    end
  end

  describe 'échec de l’envoi du SMS' do
    before do
      stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
        .to_return(status: 200, body: { 'erreurs' => { '1' => 'Clé API invalide' } }.to_json)
    end

    it 'laisse l’utilisateur sur la page de code, alerté, avec sa session en attente intacte' do
      post_login

      expect(response).to redirect_to('/admin/two_factor')
      follow_redirect!
      expect(response.body).to include('envoi du code a échoué')

      # La session en attente survit : le bouton « Renvoyer un code » reste utilisable.
      get '/admin/two_factor'
      expect(response).to have_http_status(:ok)

      get '/admin/children'
      expect(response).to redirect_to(new_admin_user_session_path)
    end
  end

  describe 'panne réseau pendant l’envoi du SMS' do
    before do
      stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/sms').to_raise(HTTP::ConnectionError)
    end

    # HTTP.post n'est rescué nulle part dans SendMessageService : sans garde,
    # une coupure réseau transforme le POST de login en 500.
    it 'mène quand même à la page de code, sans exception ni session ouverte' do
      post_login

      expect(response).to redirect_to('/admin/two_factor')
      follow_redirect!
      expect(response.body).to include('envoi du code a échoué')

      get '/admin/children'
      expect(response).to redirect_to(new_admin_user_session_path)
    end
  end

  describe 'compte 2FA sans numéro' do
    before { admin_user.update_columns(phone_number: nil) }

    it 'refuse la connexion et renvoie vers le login' do
      post_login

      expect(response).to redirect_to(new_admin_user_session_path)
      follow_redirect!
      expect(response.body).to include('Contactez un administrateur')

      get '/admin/children'
      expect(response).to redirect_to(new_admin_user_session_path)
    end
  end

  describe 'accès direct à la page de code' do
    it 'renvoie au login sans session en attente' do
      get '/admin/two_factor'
      expect(response).to redirect_to(new_admin_user_session_path)
    end

    it 'renvoie au login si la session en attente a plus de 10 minutes' do
      post_login
      travel_to(11.minutes.from_now) do
        get '/admin/two_factor'
        expect(response).to redirect_to(new_admin_user_session_path)
      end
    end
  end

  describe 'validation du code' do
    # Le code n'est jamais persisté en clair : on l'intercepte à la génération.
    def login_and_capture_code(remember: false)
      code = nil
      allow_any_instance_of(AdminUser).to receive(:generate_otp!).and_wrap_original do |method, *args|
        code = method.call(*args)
      end
      post_login(remember: remember)
      code
    end

    it 'ouvre la session avec le bon code' do
      code = login_and_capture_code

      post '/admin/two_factor/verify', params: { otp_code: code }
      expect(response).to redirect_to('/admin')

      get '/admin/children'
      expect(response).to have_http_status(:ok)
    end

    it 'refuse un mauvais code et laisse l\'utilisateur déconnecté' do
      login_and_capture_code

      post '/admin/two_factor/verify', params: { otp_code: '000000' }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Code incorrect')

      get '/admin/children'
      expect(response).to redirect_to(new_admin_user_session_path)
    end

    # On vieillit le code seul : au-delà de 10 minutes, c'est la session en
    # attente qui expirerait d'abord et `verify_otp` ne serait jamais appelé.
    it 'refuse un code expiré et laisse l\'utilisateur déconnecté' do
      code = login_and_capture_code
      admin_user.reload.update_columns(otp_sent_at: 11.minutes.ago)

      post '/admin/two_factor/verify', params: { otp_code: code }
      expect(response.body).to include('expiré')

      get '/admin/children'
      expect(response).to redirect_to(new_admin_user_session_path)
    end

    it 'bloque après 5 codes faux' do
      code = login_and_capture_code

      4.times { post '/admin/two_factor/verify', params: { otp_code: '000000' } }
      post '/admin/two_factor/verify', params: { otp_code: '000000' }
      expect(response.body).to include('Trop de tentatives')

      post '/admin/two_factor/verify', params: { otp_code: code }
      get '/admin/children'
      expect(response).to redirect_to(new_admin_user_session_path)
    end

    # La case cochée vaut pour les deux facteurs : pendant sept jours, ce
    # navigateur rouvre une session sans mot de passe ni code.
    it 'pose un cookie « se souvenir de moi » quand la case était cochée' do
      code = login_and_capture_code(remember: true)

      post '/admin/two_factor/verify', params: { otp_code: code }

      expect(cookies['remember_admin_user_token']).to be_present

      get '/admin/children'
      expect(response).to have_http_status(:ok)
    end

    it 'ne pose aucun cookie « se souvenir de moi » quand la case n’était pas cochée' do
      code = login_and_capture_code(remember: false)

      post '/admin/two_factor/verify', params: { otp_code: code }

      expect(cookies['remember_admin_user_token']).to be_blank
    end

    it 'limite la mémorisation à sept jours' do
      expect(Devise.remember_for).to eq(7.days)
    end

    it 'filtre le paramètre otp_code dans les logs applicatifs (ne journalise jamais le code en clair)' do
      filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

      filtered = filter.filter('otp_code' => '123456')

      expect(filtered['otp_code']).to eq('[FILTERED]')
    end
  end

  describe 'renvoi du code' do
    before { post_login }

    it 'refuse un renvoi dans la minute' do
      post '/admin/two_factor/resend'
      expect(response).to redirect_to('/admin/two_factor')
      follow_redirect!
      expect(response.body).to include('Patientez')
      expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms').once
    end

    it 'accepte un renvoi après une minute et invalide le code précédent' do
      previous_digest = admin_user.reload.otp_code_digest

      travel_to(61.seconds.from_now) do
        post '/admin/two_factor/resend'
        expect(response).to redirect_to('/admin/two_factor')
      end

      expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms').twice
      expect(admin_user.reload.otp_code_digest).not_to eq(previous_digest)
    end

    it 'gère une panne réseau sans erreur 500 et laisse l’utilisateur déconnecté' do
      stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/sms').to_raise(HTTP::ConnectionError)

      travel_to(61.seconds.from_now) do
        post '/admin/two_factor/resend'

        expect(response).to redirect_to('/admin/two_factor')
        follow_redirect!
        expect(response.body).to include('envoi du code a échoué')
      end

      get '/admin/children'
      expect(response).to redirect_to(new_admin_user_session_path)
    end

    # Sans quoi la boucle « 5 codes faux → renvoi gratuit → 5 codes faux »
    # rendrait le plafond de tentatives inopérant.
    it 'refuse encore un renvoi dans la minute après un blocage pour trop de tentatives' do
      AdminUser::OTP_MAX_ATTEMPTS.times { post '/admin/two_factor/verify', params: { otp_code: '000000' } }

      post '/admin/two_factor/resend'
      expect(response).to redirect_to('/admin/two_factor')
      follow_redirect!
      expect(response.body).to include('Patientez')
      expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms').once
    end

    # Le code renvoyé est valable dix minutes : la session en attente ne doit
    # pas mourir avant lui sur un « votre session a expiré » trompeur.
    it 'repousse la fenêtre de la session en attente' do
      travel_to(9.minutes.from_now) do
        post '/admin/two_factor/resend'
        expect(response).to redirect_to('/admin/two_factor')
      end

      travel_to(15.minutes.from_now) do
        get '/admin/two_factor'
        expect(response).to have_http_status(:ok)
      end
    end

    # On dépasse la minute pour que la limite d'envoi ne masque pas le sujet :
    # sans garde, c'est bien la tentative d'envoi qui casse.
    it 'renvoie au login si le numéro a été retiré du compte entre-temps' do
      admin_user.update_columns(phone_number: nil)

      travel_to(61.seconds.from_now) do
        post '/admin/two_factor/resend'

        expect(response).to redirect_to(new_admin_user_session_path)
        follow_redirect!
        expect(response.body).to include('Contactez un administrateur')

        get '/admin/two_factor'
        expect(response).to redirect_to(new_admin_user_session_path)
      end

      expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms').once
    end
  end
end
