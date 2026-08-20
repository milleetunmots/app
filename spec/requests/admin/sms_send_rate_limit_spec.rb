require 'rails_helper'

RSpec.describe 'Plafonnement des envois Spot-Hit', type: :request do
  let(:limit_message) { "Vous avez atteint la limite d'envoi de messages. Aucun message n'a pu être envoyé. Contactez un admin." }
  # Le message contient des apostrophes, échappées dans le HTML rendu.
  let(:escaped_limit_message) { ERB::Util.html_escape(limit_message) }
  let!(:group) { FactoryBot.create(:group) }
  let!(:parent) { FactoryBot.create(:parent) }
  let!(:child) do
    FactoryBot.create(
      :child,
      parent1: parent,
      should_contact_parent1: true,
      group: group,
      group_status: 'active'
    )
  end

  before do
    stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/sms').
      to_return(status: 200, body: '{}')
    stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').
      to_return(status: 200, body: { success: true, campaign_id: '123' }.to_json)
  end

  # Sature le quota de l'utilisatrice connectée.
  def saturate(admin_user)
    FactoryBot.create(:sms_send_record, admin_user: admin_user, recipients_count: 50)
  end

  describe 'formulaire Message' do
    let(:admin_user) { FactoryBot.create(:admin_user, user_role: 'contributor') }

    before { sign_in admin_user }

    def program_sms
      post '/admin/message/program_sms', params: {
        planned_date: Time.zone.today.to_s,
        planned_hour: Time.zone.now.strftime('%H:%M'),
        recipients: ["parent.#{parent.id}"],
        group_status: ['active'],
        message: 'Bonjour'
      }
    end

    it "programme le message sous le plafond et comptabilise l'envoi" do
      expect { program_sms }.to change(SmsSendRecord, :count).by(1)
      expect(SmsSendRecord.last.recipients_count).to eq(1)
    end

    it "affiche le message de dépassement et n'envoie rien au-dessus du plafond" do
      saturate(admin_user)

      expect { program_sms }.not_to change(SmsSendRecord, :count)
      expect(flash[:alert]).to include(limit_message)
      expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
    end

    it "n'applique pas le plafond à un super_admin" do
      super_admin = FactoryBot.create(:admin_user, user_role: 'super_admin')
      sign_in super_admin
      saturate(super_admin)

      expect { program_sms }.not_to change(SmsSendRecord, :count)
      expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
    end
  end

  describe "batch action de vérification d'adresse" do
    let(:admin_user) { FactoryBot.create(:admin_user, user_role: 'contributor') }

    before { sign_in admin_user }

    def send_address_verification
      post '/admin/children/batch_action', params: {
        batch_action: 'send_address_verification_message',
        collection_selection: [child.id]
      }
    end

    it "comptabilise l'envoi avec le nombre de parents résolus" do
      expect { send_address_verification }.to change(SmsSendRecord, :count).by(1)
      expect(SmsSendRecord.last.recipients_count).to eq(1)
    end

    it 'ne transmet rien et affiche le message au-dessus du plafond' do
      saturate(admin_user)

      expect { send_address_verification }.not_to change(SmsSendRecord, :count)
      expect(flash[:alert]).to include(limit_message)
      expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
      expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
    end
  end

  describe 'batch action SMS de continuation' do
    let(:admin_user) { FactoryBot.create(:admin_user, user_role: 'contributor') }

    before { sign_in admin_user }

    def generate_quit_sms
      post '/admin/children/batch_action', params: {
        batch_action: 'generate_quit_sms',
        collection_selection: [child.id]
      }
    end

    it 'met les enfants en pause sous le plafond' do
      generate_quit_sms

      expect(child.reload.group_status).to eq('paused')
    end

    it 'laisse les enfants actifs au-dessus du plafond' do
      saturate(admin_user)

      generate_quit_sms

      expect(child.reload.group_status).to eq('active')
    end

    it 'ne transmet rien, ne comptabilise rien et affiche le message au-dessus du plafond' do
      saturate(admin_user)

      expect { generate_quit_sms }.not_to change(SmsSendRecord, :count)
      expect(flash[:alert]).to include(limit_message)
      expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
      expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
    end
  end

  describe "création d'atelier" do
    let(:admin_user) { FactoryBot.create(:admin_user, user_role: 'contributor') }
    let(:invitation_message) { 'Venez nombreux a notre atelier' }

    before { sign_in admin_user }

    def create_workshop
      post '/admin/workshops', params: {
        workshop: {
          workshop_date: 3.weeks.from_now.to_date.to_s,
          first_workshop_time_slot: '11:00',
          animator_id: admin_user.id,
          address: '12 rue de la Paix',
          postal_code: '75020',
          city_name: 'Paris',
          location: 'Mediatheque',
          invitation_message: invitation_message,
          workshop_land: 'Paris 20 eme',
          parent_ids: parent.id.to_s
        }
      }
    end

    it "crée l'atelier sous le plafond" do
      expect { create_workshop }.to change(Workshop, :count).by(1)
    end

    it "ne persiste pas l'atelier au-dessus du plafond" do
      saturate(admin_user)

      expect { create_workshop }.not_to change(Workshop, :count)
    end

    it 'ré-affiche le formulaire avec le message et les données saisies' do
      saturate(admin_user)

      create_workshop

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(escaped_limit_message)
      expect(response.body).to include(invitation_message)
    end

    it "n'affiche pas le message trompeur d'absence d'invitation" do
      saturate(admin_user)

      create_workshop

      expect(response.body).not_to include('Aucune invitation n&#39;a pu être envoyée')
    end

    it 'ne comptabilise ni ne transmet rien au-dessus du plafond' do
      saturate(admin_user)

      expect { create_workshop }.not_to change(SmsSendRecord, :count)
      expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
      expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
    end
  end

  describe 'page des envois comptabilisés' do
    let!(:record) { FactoryBot.create(:sms_send_record, recipients_count: 7) }

    it 'est accessible à un super_admin' do
      sign_in FactoryBot.create(:admin_user, user_role: 'super_admin')

      get '/admin/sms_send_records'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('7')
    end

    %w[contributor reader caller animator].each do |role|
      it "est refusée à un #{role}" do
        sign_in FactoryBot.create(:admin_user, user_role: role)

        get '/admin/sms_send_records'

        expect(response).not_to have_http_status(:ok)
      end
    end
  end

  describe 'formulaire utilisateur' do
    let!(:target) { FactoryBot.create(:admin_user, user_role: 'contributor') }

    it 'expose les plafonds à un super_admin' do
      sign_in FactoryBot.create(:admin_user, user_role: 'super_admin')

      get "/admin/admin_users/#{target.id}/edit"

      expect(response.body).to include('Plafond de destinataires par heure')
      expect(response.body).to include('Plafond de destinataires par jour')
    end

    it 'ne les expose pas à un contributeur' do
      sign_in target

      get "/admin/admin_users/#{target.id}/edit"

      expect(response.body).not_to include('Plafond de destinataires par heure')
    end
  end
end
