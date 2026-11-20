require 'rails_helper'

RSpec.describe Media::SyncRcsModelsService do
  # L'équipe enregistre le trio dans ActiveAdmin, qui lance la synchronisation : ici exécutée tout de suite.
  def create_from_admin(**attributes)
    FactoryBot.create(:media_text_messages_bundle, **attributes).tap { |bundle| Media::SyncRcsModelsJob.perform_now(bundle.id, [1, 2, 3]) }.reload
  end

  def save_from_admin(bundle, **attributes)
    bundle.update!(**attributes)
    Media::SyncRcsModelsJob.perform_now(bundle.id, bundle.changed_rcs_message_indexes)
    bundle
  end

  it "n'appelle plus Spot-Hit quand un trio est enregistré hors des écrans de l'équipe" do
    WebMock::RequestRegistry.instance.reset!

    FactoryBot.create(:media_text_messages_bundle, body1: 'Bonjour !', body2: nil, body3: nil)

    expect(WebMock).not_to have_requested(:any, /spot-hit\.fr/)
  end

  describe 'création du modèle Spot-Hit à l\'enregistrement' do
    def created_models
      WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                              .select { |signature| signature.uri.path == '/api/rcs/model/create' }
                              .map { |signature| JSON.parse(Rack::Utils.parse_nested_query(signature.body)['model']) }
    end

    [120, 300].each do |bytesize|
      it "crée un modèle texte pour un nouveau message sans image de #{bytesize} octets et l'enregistre" do
        stub_request(:post, SpotHit::CreateRcsModelService::URL)
          .to_return(status: 200, body: { success: true, id: 4521 }.to_json)
        bundle = create_from_admin(body1: 'Bonjour !', body2: nil, body3: nil)
        body2 = "Chantez une comptine. #{'a' * (bytesize - 22)}"

        save_from_admin(bundle, body2: body2)

        model = created_models.find { |m| m.dig('content', 'text', 'text')&.start_with?('Chantez une comptine') }
        expect(model['type']).to eq('text')
        expect(bundle.reload).to have_attributes(rcs_media2_id: 4521, rcs_text_template2: true)
      end
    end

    it 'retire le préfixe « 1001mots : » du texte du modèle sans toucher au texte du trio' do
      body = "1001mots : cette semaine, chantez une comptine avec {PRENOM_ENFANT} pendant le bain. #{'a' * 120}"

      bundle = create_from_admin(body1: body, body2: nil, body3: nil)

      expect(created_models.last.dig('content', 'text', 'text')).to start_with('Cette semaine, chantez une comptine')
      expect(bundle.reload.body1).to eq(body)
    end

    it 'garde le lien dans le texte du modèle texte, sans bouton' do
      video = FactoryBot.create(:media_video, name: 'Comptine du bain')

      create_from_admin(body1: "Découvrez\nla comptine de la semaine.", link1: video, body2: nil, body3: nil)

      expect(created_models.last).to eq(
        'type' => 'text',
        'content' => {
          'text' => { 'text' => 'Découvrez<br>la comptine de la semaine. {URL}', 'suggestions' => [] },
          'property' => { 'stop' => false }
        }
      )
    end
  end

  describe "mise à jour d'un modèle texte à l'enregistrement" do
    include ActiveJob::TestHelper

    def bundle_with_text_template(body)
      bundle = create_from_admin(body1: body, body2: nil, body3: nil)
      bundle.update_columns(rcs_media1_id: 4521, rcs_text_template1: true)
      WebMock::RequestRegistry.instance.reset!
      bundle.reload
    end

    def modify_request_for(rcs_media_id)
      WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                              .select { |signature| signature.uri.path == '/api/rcs/model/modify' }
                              .map { |signature| Rack::Utils.parse_nested_query(signature.body) }
                              .find { |form| form['id'] == rcs_media_id.to_s }
    end

    it 'met à jour le modèle texte avec le nouveau texte, sans en créer un autre' do
      stub_request(:post, SpotHit::UpdateRcsModelService::URL).to_return(status: 200, body: { success: true, id: 4521 }.to_json)
      bundle = bundle_with_text_template('Chantez une comptine ce soir.')

      save_from_admin(bundle, body1: 'Lisez une histoire ce soir.')

      model = JSON.parse(modify_request_for(4521)['model'])
      expect(model).to include('type' => 'text')
      expect(model.dig('content', 'text', 'text')).to eq('Lisez une histoire ce soir.')
      expect(WebMock).not_to have_requested(:post, SpotHit::CreateRcsModelService::URL)
    end

    it 'met à jour le modèle texte sans programmer de suppression quand le texte dépasse 160 octets' do
      stub_request(:post, SpotHit::UpdateRcsModelService::URL).to_return(status: 200, body: { success: true, id: 4521 }.to_json)
      bundle = bundle_with_text_template('a' * 150)

      expect { save_from_admin(bundle, body1: 'a' * 210) }.not_to have_enqueued_job(SpotHit::DeleteRcsModelJob)

      expect(modify_request_for(4521)).to be_present
      expect(bundle.reload).to have_attributes(rcs_media1_id: 4521, rcs_text_template1: true)
    end

    it 'enregistre le nouveau texte et alerte Rollbar quand Spot-Hit refuse la mise à jour' do
      stub_request(:post, SpotHit::UpdateRcsModelService::URL)
        .to_return(status: 200, body: { success: false, error: 'Modèle introuvable' }.to_json)
      allow(Rollbar).to receive(:error)
      bundle = bundle_with_text_template('Chantez une comptine ce soir.')

      save_from_admin(bundle, body1: 'Lisez une histoire ce soir.')

      expect(bundle.reload.body1).to eq('Lisez une histoire ce soir.')
      expect(Rollbar).to have_received(:error).with(
        'SpotHit::UpdateRcsModelService',
        hash_including(text_messages_bundle_id: bundle.id, errors: [a_string_including('Erreur lors de la modification du modèle RCS')])
      )
    end
  end

  describe 'remplacement du modèle quand une image est ajoutée ou retirée' do
    include ActiveJob::TestHelper

    def bundle_with_template(rcs_media_id, image: nil)
      bundle = create_from_admin(body1: 'Chantez une comptine ce soir.', body2: nil, body3: nil)
      bundle.update_columns(image1_id: image&.id, rcs_media1_id: rcs_media_id, rcs_text_template1: image.nil?)
      WebMock::RequestRegistry.instance.reset!
      bundle.reload
    end

    def created_model_type
      signature = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.find { |s| s.uri.path == '/api/rcs/model/create' }
      body = signature.body.b
      body = CGI.unescape(body).b unless body.include?('Content-Disposition')
      body[/\{"type":"(\w+)"/n, 1]
    end

    it "crée un modèle carte quand une image est ajoutée et programme la suppression de l'ancien modèle texte" do
      stub_request(:post, SpotHit::CreateRcsModelService::URL).to_return(status: 200, body: { success: true, id: 7000 }.to_json)
      bundle = bundle_with_template(4521)

      expect { save_from_admin(bundle, image1_id: FactoryBot.create(:media_image).id) }
        .to have_enqueued_job(SpotHit::DeleteRcsModelJob).with(4521).at(a_value_within(1.minute).of(2.months.from_now))

      expect(created_model_type).to eq('card')
      expect(bundle.reload).to have_attributes(rcs_media1_id: 7000, rcs_text_template1: false)
    end

    it 'garde le modèle texte et alerte Rollbar quand Spot-Hit refuse le modèle carte' do
      bundle = bundle_with_template(4521)
      image = FactoryBot.create(:media_image)
      stub_request(:post, SpotHit::CreateRcsModelService::URL)
        .to_return(status: 200, body: { success: false, error: 'Image refusée' }.to_json)
      allow(Rollbar).to receive(:error)

      expect { save_from_admin(bundle, image1_id: image.id) }.not_to have_enqueued_job(SpotHit::DeleteRcsModelJob)

      expect(bundle.reload).to have_attributes(image1_id: image.id, rcs_media1_id: 4521, rcs_text_template1: true)
      expect(Rollbar).to have_received(:error).with(
        'SpotHit::CreateRcsModelService',
        hash_including(text_messages_bundle_id: bundle.id, errors: [a_string_including('Erreur lors de la création du modèle RCS')])
      )
    end

    it "crée un modèle texte quand l'image est retirée et programme la suppression de l'ancien modèle carte" do
      stub_request(:post, SpotHit::CreateRcsModelService::URL).to_return(status: 200, body: { success: true, id: 8000 }.to_json)
      bundle = bundle_with_template(3310, image: FactoryBot.create(:media_image))

      expect { save_from_admin(bundle, image1_id: nil) }
        .to have_enqueued_job(SpotHit::DeleteRcsModelJob).with(3310).at(a_value_within(1.minute).of(2.months.from_now))

      expect(created_model_type).to eq('text')
      expect(bundle.reload).to have_attributes(rcs_media1_id: 8000, rcs_text_template1: true)
    end
  end

  describe "cas où l'enregistrement ne crée ni ne modifie de modèle" do
    include ActiveJob::TestHelper

    def with_env(key, value)
      previous = ENV.fetch(key, nil)
      ENV[key] = value
      yield
    ensure
      previous.nil? ? ENV.delete(key) : ENV[key] = previous
    end

    it "programme la suppression du modèle d'un message effacé et l'oublie" do
      bundle = create_from_admin(body1: 'Bonjour !', body2: 'À demain !', body3: 'Chantez une comptine ce soir.')
      bundle.update_columns(rcs_media3_id: 4521, rcs_text_template3: true)

      expect { save_from_admin(bundle.reload, body3: '') }
        .to have_enqueued_job(SpotHit::DeleteRcsModelJob).with(4521).at(a_value_within(1.minute).of(2.months.from_now))

      expect(bundle.reload).to have_attributes(rcs_media3_id: nil, rcs_text_template3: false)
    end

    it "n'envoie pas à Spot-Hit un modèle texte dont le contenu est bloqué et alerte Rollbar" do
      allow(Rollbar).to receive(:error)

      bundle = with_env('URL_FILTER_BLOCKING_ENABLED', 'true') do
        create_from_admin(body1: 'Regardez : https://non-whitelisted.example.com/page', body2: nil, body3: nil)
      end

      expect(bundle).to be_persisted
      expect(WebMock).not_to have_requested(:post, SpotHit::CreateRcsModelService::URL)
      expect(Rollbar).to have_received(:error).with(
        'SpotHit::CreateRcsModelService',
        hash_including(text_messages_bundle_id: bundle.id, errors: [BlockedSendAttempt::SendGuard::BLOCKED_MESSAGE])
      )
    end

    it "n'appelle pas Spot-Hit depuis staging quand le texte d'un modèle texte change" do
      bundle = create_from_admin(body1: 'Chantez une comptine ce soir.', body2: nil, body3: nil)
      bundle.update_columns(rcs_media1_id: 4521, rcs_text_template1: true)
      WebMock::RequestRegistry.instance.reset!

      with_env('SPOT_HIT_SAFEGUARD', 'true') { save_from_admin(bundle.reload, body1: 'Lisez une histoire ce soir.') }

      expect(bundle.reload.body1).to eq('Lisez une histoire ce soir.')
      expect(WebMock).not_to have_requested(:any, /spot-hit\.fr/)
    end
  end

  describe 'cas existants de la synchronisation' do
    let(:image) { FactoryBot.create(:media_image) }
    let!(:bundle) do
      text_messages = create_from_admin(body2: nil, body3: nil)
      text_messages.update_columns(rcs_media1_id: 123, image1_id: image.id, rcs_text_template1: false)
      text_messages.reload
    end

    context 'when rcs_media_id is present and image_id is nil' do
      it 'enqueues DeleteRcsModelJob with the rcs_media_id' do
        allow(SpotHit::DeleteRcsModelJob).to receive(:set).and_return(SpotHit::DeleteRcsModelJob)
        expect(SpotHit::DeleteRcsModelJob).to receive(:perform_later).with(123)
        save_from_admin(bundle, image1_id: nil)
      end

      it 'remplace le modèle carte par le modèle texte créé' do
        allow(SpotHit::DeleteRcsModelJob).to receive(:set).and_return(SpotHit::DeleteRcsModelJob)
        save_from_admin(bundle, image1_id: nil)
        expect(bundle.reload).to have_attributes(rcs_media1_id: 1, rcs_text_template1: true)
      end
    end

    context 'when rcs_media_id is present and image changed' do
      let(:bundle) do
        text_messages = create_from_admin(body2: nil, body3: nil)
        text_messages.update_columns(rcs_media1_id: 456, image1_id: image.id, rcs_text_template1: false)
        text_messages.reload
      end

      let(:service_result) { double('service_result', errors: []) }
      let(:service_instance) { double('service_instance', call: service_result) }

      it 'calls UpdateRcsModelService when body changes' do
        expect(SpotHit::UpdateRcsModelService).to receive(:new)
          .with(text_messages_bundle: bundle, message_index: 1)
          .and_return(service_instance)
        save_from_admin(bundle, body1: 'new body')
      end

      it 'calls UpdateRcsModelService when rcs_title changes' do
        expect(SpotHit::UpdateRcsModelService).to receive(:new)
          .with(text_messages_bundle: bundle, message_index: 1)
          .and_return(service_instance)
        save_from_admin(bundle, rcs_title1: 'new title')
      end

      it 'calls UpdateRcsModelService when image changes' do
        new_image = FactoryBot.create(:media_image)
        expect(SpotHit::UpdateRcsModelService).to receive(:new)
          .with(text_messages_bundle: bundle, message_index: 1)
          .and_return(service_instance)
        save_from_admin(bundle, image1_id: new_image.id)
      end

      it 'reports to Rollbar when UpdateRcsModelService has errors' do
        error_result = double('error_result', errors: ['SpotHit error'])
        error_instance = double('error_instance', call: error_result)
        allow(SpotHit::UpdateRcsModelService).to receive(:new).and_return(error_instance)
        expect(Rollbar).to receive(:error).with('SpotHit::UpdateRcsModelService', anything)
        save_from_admin(bundle, body1: 'new body')
      end
    end

    context 'when rcs_media_id is nil and image_id is present' do
      let(:bundle) do
        text_messages = create_from_admin(body2: nil, body3: nil)
        text_messages.update_columns(rcs_media1_id: nil)
        text_messages.reload
      end

      it 'calls CreateRcsModelService when image is added' do
        service_result = double('service_result', errors: [])
        service_instance = double('service_instance', call: service_result)
        expect(SpotHit::CreateRcsModelService).to receive(:new)
          .with(text_messages_bundle: bundle, message_index: 1)
          .and_return(service_instance)
        save_from_admin(bundle, image1_id: image.id)
      end

      it 'reports to Rollbar when CreateRcsModelService has errors' do
        error_result = double('error_result', errors: ['SpotHit error'])
        error_instance = double('error_instance', call: error_result)
        allow(SpotHit::CreateRcsModelService).to receive(:new).and_return(error_instance)
        expect(Rollbar).to receive(:error).with('SpotHit::CreateRcsModelService', anything)
        save_from_admin(bundle, image1_id: image.id)
      end
    end
  end
end
