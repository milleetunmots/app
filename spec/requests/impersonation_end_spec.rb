require 'rails_helper'

RSpec.describe "Fin d'une connexion en tant qu'accompagnante", type: :request do
  let(:clara) { FactoryBot.create(:admin_user, user_role: 'contributor') }
  let(:marie) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let(:paul) { FactoryBot.create(:admin_user, user_role: 'caller') }

  let!(:leo) { FactoryBot.create(:child, first_name: 'Léo').tap { |child| child.child_support.update!(supporter: marie) } }
  let!(:nina) { FactoryBot.create(:child, first_name: 'Nina').tap { |child| child.child_support.update!(supporter: paul) } }

  before do
    sign_in clara
    post "/admin/admin_users/#{marie.id}/impersonation"
  end

  def current_impersonation
    AdminUserImpersonation.last
  end

  shared_examples 'une fin automatique' do
    it 'ferme la ligne du journal' do
      get '/admin'

      expect(current_impersonation.ended_at).to be_within(5.seconds).of(Time.current)
    end

    it "redirige vers le tableau de bord de l'opérateur avec le message" do
      get '/admin/children'

      expect(response).to redirect_to('/admin')
      expect(flash[:alert]).to eq(message)
    end

    it "rend la vue de l'opérateur aux requêtes suivantes" do
      get '/admin/children'
      get '/admin/children'

      expect(response.body).to include('Léo')
      expect(response.body).to include('Nina')
    end
  end

  context 'quand la cible est désactivée pendant la connexion' do
    let(:message) { "La connexion en tant que #{marie.name} a pris fin : le compte est désactivé" }

    before { marie.update!(is_disabled: true) }

    it_behaves_like 'une fin automatique'
  end

  context "quand la cible n'est plus une accompagnante" do
    let(:message) { "La connexion en tant que #{marie.name} a pris fin : ce compte n'est plus une accompagnante ni une animatrice" }

    before { marie.update!(user_role: 'reader') }

    it_behaves_like 'une fin automatique'
  end

  context "quand l'opérateur perd le droit de se connecter en tant qu'accompagnante" do
    let(:message) { "La connexion en tant que #{marie.name} a pris fin : vos droits ne la permettent plus" }

    before { clara.update!(user_role: 'reader') }

    it_behaves_like 'une fin automatique'
  end

  context 'quand la requête qui découvre la fin est une écriture' do
    it "ne l'exécute pas sous le compte de l'opérateur" do
      marie.update!(is_disabled: true)

      expect { post '/admin/tasks', params: { task: { title: 'Rappeler Léo' } } }.not_to change(Task, :count)

      expect(response).to redirect_to('/admin')
    end
  end

  context "quand l'opérateur se déconnecte" do
    it 'ferme la ligne du journal' do
      delete destroy_admin_user_session_path

      expect(current_impersonation.ended_at).to be_within(5.seconds).of(Time.current)
    end

    it 'ne laisse aucune connexion en tant que sans fin pour cet opérateur' do
      delete destroy_admin_user_session_path

      expect(AdminUserImpersonation.ongoing.where(operator: clara)).to be_empty
    end
  end

  context 'quand la ligne a déjà été fermée ailleurs' do
    before { current_impersonation.finish! }

    it "rend la vue de l'opérateur sans erreur ni message" do
      get '/admin/children'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Léo')
      expect(response.body).to include('Nina')
    end

    it 'ne modifie pas la fin déjà renseignée' do
      ended_at = current_impersonation.reload.ended_at

      get '/admin/children'

      expect(current_impersonation.reload.ended_at).to eq(ended_at)
    end
  end

  context 'quand la connexion est démarrée puis quittée par une cible qui a la double authentification' do
    it 'ne touche pas au compte de la cible ni ne lui envoie de code' do
      marie.update!(phone_number: '0612345678', two_factor_enabled: true)
      marie.update!(remember_created_at: 2.days.ago.change(usec: 0))
      before_state = marie.reload.attributes.slice('updated_at', 'remember_created_at', 'otp_code_digest', 'otp_sent_at', 'otp_attempts')

      delete '/admin/impersonation'

      expect(marie.reload.attributes.slice(*before_state.keys)).to eq(before_state)
    end
  end
end
