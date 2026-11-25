require 'rails_helper'
require 'rake'

RSpec.describe 'rcs:rename_templates' do
  before(:all) do
    Rake.application.rake_require('tasks/rename_rcs_templates', [Rails.root.join('lib').to_s])
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task['rcs:rename_templates'] }

  before { task.reenable }

  def modified_models
    WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                            .select { |signature| signature.uri.path == '/api/rcs/model/modify' }
                            .map { |signature| Rack::Utils.parse_nested_query(signature.body) }
  end

  context 'quand des messages de trios ont un modèle' do
    it 'renvoie chaque modèle avec son nouveau nom, sans en créer' do
      stub_request(:post, SpotHit::UpdateRcsModelService::URL).to_return(status: 200, body: { success: true }.to_json)
      bundle = FactoryBot.create(
        :media_text_messages_bundle,
        name: 'Fin du programme', key: 'fin_programme', body1: 'Le programme est terminé.', body2: 'Merci à vous.', body3: nil,
        rcs_media1_id: 4521, rcs_text_template1: true, rcs_media2_id: 4522, rcs_text_template2: true
      )

      expect { task.invoke }.to output(/Templates renamed: 2.*Errors: 0/m).to_stdout

      expect(modified_models.map { |form| [form['id'], JSON.parse(form['model'])['name']] }).to contain_exactly(
        ['4521', "Auto fin_programme ##{bundle.id}"],
        ['4522', "Auto fin_programme M2 ##{bundle.id}"]
      )
      expect(WebMock).not_to have_requested(:post, SpotHit::CreateRcsModelService::URL)
    end
  end

  context "quand un message n'a pas de modèle ou que le trio est archivé" do
    it "ne l'envoie pas à Spot-Hit" do
      FactoryBot.create(:media_text_messages_bundle, body1: 'Sans modèle.', body2: nil, body3: nil)
      FactoryBot.create(:media_text_messages_bundle, body1: 'Archivé.', body2: nil, body3: nil, rcs_media1_id: 4521, rcs_text_template1: true, discarded_at: Time.current)

      expect { task.invoke }.to output(/Templates renamed: 0/).to_stdout

      expect(WebMock).not_to have_requested(:post, /spot-hit\.fr/)
    end
  end

  context "quand Spot-Hit refuse la modification d'un modèle" do
    it 'continue avec les suivants et affiche un bilan avec le message de Spot-Hit' do
      FactoryBot.create(:media_text_messages_bundle, body1: 'Premier, refusé.', body2: nil, body3: nil, rcs_media1_id: 4521, rcs_text_template1: true)
      FactoryBot.create(:media_text_messages_bundle, body1: 'Second, accepté.', body2: nil, body3: nil, rcs_media1_id: 4522, rcs_text_template1: true)
      stub_request(:post, SpotHit::UpdateRcsModelService::URL).to_return(status: 200, body: { success: true }.to_json)
      stub_request(:post, SpotHit::UpdateRcsModelService::URL)
        .with { |request| Rack::Utils.parse_nested_query(request.body)['id'] == '4521' }
        .to_return(status: 200, body: { success: false, error: 'Model is not found.' }.to_json)

      expect { task.invoke }.to output(/ERROR - .*Model is not found.*Templates renamed: 1.*Errors: 1/m).to_stdout
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
      FactoryBot.create(:media_text_messages_bundle, body1: 'Avec modèle.', body2: nil, body3: nil, rcs_media1_id: 4521, rcs_text_template1: true)

      expect { task.invoke }.to raise_error(SystemExit).and output(/SPOT_HIT_SAFEGUARD/).to_stdout

      expect(WebMock).not_to have_requested(:any, /spot-hit\.fr/)
    end
  end
end
