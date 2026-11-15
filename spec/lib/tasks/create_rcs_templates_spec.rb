require 'rails_helper'
require 'rake'

RSpec.describe 'rcs:create_templates' do
  before(:all) do
    Rake.application.rake_require('tasks/create_rcs_templates', [Rails.root.join('lib').to_s])
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task['rcs:create_templates'] }

  before { task.reenable }

  def existing_bundle(body1:, body2: nil, rcs_media1_id: nil, image1_id: nil, rcs_text_template1: false)
    bundle = FactoryBot.create(:media_text_messages_bundle, body1: body1, body2: body2, body3: nil)
    bundle.update_columns(rcs_media1_id: rcs_media1_id, rcs_media2_id: nil, image1_id: image1_id, rcs_text_template1: rcs_text_template1)
    WebMock::RequestRegistry.instance.reset!
    bundle.reload
  end

  def created_model_texts
    WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                            .select { |signature| signature.uri.path == '/api/rcs/model/create' }
                            .map { |signature| CGI.unescape(signature.body.b).force_encoding('UTF-8') }
  end

  context 'quand un trio non archivé a des messages sans image ni modèle' do
    [300, 120].each do |bytesize|
      it "crée un modèle texte pour un message de #{bytesize} octets et enregistre son identifiant" do
        stub_request(:post, SpotHit::CreateRcsModelService::URL).to_return(status: 200, body: { success: true, id: 4521 }.to_json)
        body = "Chantez une comptine. #{'a' * (bytesize - 22)}"
        bundle = existing_bundle(body1: body)

        expect { task.invoke }.to output(/text template/).to_stdout

        expect(created_model_texts.first).to include('"type":"text"')
        expect(bundle.reload).to have_attributes(rcs_media1_id: 4521, rcs_text_template1: true)
      end
    end
  end

  context 'quand un message a déjà un modèle ou est vide' do
    it "l'ignore" do
      image = FactoryBot.create(:media_image)
      with_card = existing_bundle(body1: 'Avec image', rcs_media1_id: 3310, image1_id: image.id)
      with_text = existing_bundle(body1: 'Sans image', rcs_media1_id: 4521, rcs_text_template1: true)

      expect { task.invoke }.to output(a_string_including('already exists with ID 3310', 'already exists with ID 4521')).to_stdout

      expect(WebMock).not_to have_requested(:post, SpotHit::CreateRcsModelService::URL)
      expect(with_card.reload.rcs_media1_id).to eq(3310)
      expect(with_text.reload).to have_attributes(rcs_media1_id: 4521, rcs_media2_id: nil)
    end
  end

  context 'quand le trio est archivé' do
    it 'ne crée aucun modèle pour lui' do
      bundle = existing_bundle(body1: 'Chantez une comptine ce soir.')
      bundle.update_column(:discarded_at, Time.current)

      task.invoke

      expect(WebMock).not_to have_requested(:post, SpotHit::CreateRcsModelService::URL)
      expect(bundle.reload.rcs_media1_id).to be_nil
    end
  end

  context "quand Spot-Hit refuse le modèle d'un trio" do
    it 'continue avec les trios suivants et affiche un bilan avec le message de Spot-Hit' do
      refused = existing_bundle(body1: 'Premier trio, refusé par Spot-Hit.')
      accepted = existing_bundle(body1: 'Second trio, accepté par Spot-Hit.')
      stub_request(:post, SpotHit::CreateRcsModelService::URL).to_return(status: 200, body: { success: true, id: 4521 }.to_json)
      stub_request(:post, SpotHit::CreateRcsModelService::URL)
        .with { |request| CGI.unescape(request.body).include?('Premier trio') }
        .to_return(status: 200, body: { success: false, error: 'Modèle refusé' }.to_json)

      expect { task.invoke }.to output(/ERROR - .*Modèle refusé.*Templates created: 1.*Errors: 1/m).to_stdout

      expect(refused.reload.rcs_media1_id).to be_nil
      expect(accepted.reload.rcs_media1_id).to eq(4521)
    end
  end

  context 'en développement, quand SPOT_HIT_SAFEGUARD est absent' do
    it 'crée les modèles comme ailleurs' do
      allow(Rails.env).to receive(:development?).and_return(true)
      stub_request(:post, SpotHit::CreateRcsModelService::URL).to_return(status: 200, body: { success: true, id: 4521 }.to_json)
      bundle = existing_bundle(body1: 'Chantez une comptine ce soir.')

      expect { task.invoke }.not_to raise_error

      expect(bundle.reload.rcs_media1_id).to eq(4521)
    end
  end

  context 'quand SPOT_HIT_SAFEGUARD est actif' do
    around do |example|
      previous = ENV.fetch('SPOT_HIT_SAFEGUARD', nil)
      ENV['SPOT_HIT_SAFEGUARD'] = 'true'
      example.run
    ensure
      ENV['SPOT_HIT_SAFEGUARD'] = previous
    end

    it "s'arrête sans appeler Spot-Hit et dit pourquoi" do
      existing_bundle(body1: 'Chantez une comptine ce soir.')

      expect { task.invoke }.to raise_error(SystemExit).and output(/SPOT_HIT_SAFEGUARD/).to_stdout

      expect(WebMock).not_to have_requested(:any, /spot-hit\.fr/)
    end
  end
end
