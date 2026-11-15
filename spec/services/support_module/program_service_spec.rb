require 'rails_helper'

RSpec.describe SupportModule::ProgramService do
  def stub_spot_hit_campaigns(campaigns)
    stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').to_return do |request|
      campaigns << Rack::Utils.parse_nested_query(request.body).merge('endpoint' => 'rcs')
      { status: 200, body: { success: true, campaign_id: '123' }.to_json }
    end
    stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/sms').to_return do |request|
      campaigns << Rack::Utils.parse_nested_query(request.body).merge('endpoint' => 'sms')
      { status: 200, body: {}.to_json }
    end
    stub_request(:post, SpotHit::CreateRcsModelService::URL)
      .to_return(status: 200, body: { success: true, id: 9999 }.to_json)
  end

  def campaign_for(campaigns, text)
    campaigns.find { |campaign| (campaign['fallback_message'] || campaign['message']).to_s.start_with?(text) }
  end

  def channel_of(campaign)
    return 'SMS' if campaign['endpoint'] == 'sms'
    return 'RCS basic' if campaign['rcs_type'] == 'basic'

    "RCS single #{campaign['media_id']}"
  end

  def with_rcs_single_text(value)
    previous = ENV.fetch('RCS_SINGLE_TEXT_ENABLED', nil)
    value.nil? ? ENV.delete('RCS_SINGLE_TEXT_ENABLED') : ENV['RCS_SINGLE_TEXT_ENABLED'] = value
    yield
  ensure
    previous.nil? ? ENV.delete('RCS_SINGLE_TEXT_ENABLED') : ENV['RCS_SINGLE_TEXT_ENABLED'] = previous
  end

  def program_module_with(bundle)
    group = FactoryBot.create(:group)
    child = FactoryBot.create(:child, first_name: 'Léa', group: group, group_status: 'active')
    support_module = FactoryBot.create(:support_module)
    FactoryBot.create(:support_module_week, support_module: support_module, medium: bundle)

    SupportModule::ProgramService.new(
      support_module,
      Time.zone.today.next_occurring(:monday),
      recipients: ["parent.#{child.parent1_id}"]
    ).call
  end

  describe '#call' do
    context 'quand un message sans image a déjà un modèle RCS' do
      it "ne crée aucun nouveau modèle chez Spot-Hit et garde l'identifiant existant" do
        stub_spot_hit_campaigns([])
        bundle = FactoryBot.create(:media_text_messages_bundle, body1: 'Bonjour !', body2: 'Chantez une comptine ce soir.', body3: nil)
        bundle.update_column(:rcs_media2_id, 4521)
        WebMock::RequestRegistry.instance.reset!

        service = program_module_with(bundle)

        expect(service.errors).to be_empty
        expect(WebMock).not_to have_requested(:post, SpotHit::CreateRcsModelService::URL)
        expect(bundle.reload.rcs_media2_id).to eq(4521)
      end
    end

    context "selon l'image du message, sa taille une fois envoyé et RCS_SINGLE_TEXT_ENABLED" do
      [
        { flag: 'true', body: 'a' * 160, image: false, link: false, channel: 'RCS basic' },
        { flag: 'true', body: "#{'a' * 157}éé", image: false, link: false, channel: 'RCS single 4521' },
        { flag: 'true', body: 'é' * 80, image: false, link: false, channel: 'RCS basic' },
        { flag: 'true', body: 'a' * 300, image: false, link: false, channel: 'RCS single 4521' },
        { flag: 'true', body: 'a' * 300, image: true, link: false, channel: 'RCS single 3310' },
        { flag: nil, body: 'a' * 300, image: false, link: false, channel: 'SMS' },
        { flag: '', body: 'a' * 300, image: false, link: false, channel: 'SMS' },
        { flag: nil, body: 'a' * 120, image: false, link: false, channel: 'RCS basic' },
        { flag: nil, body: 'a' * 300, image: true, link: false, channel: 'RCS single 3310' },
        { flag: 'true', body: 'a' * 154, image: false, link: true, channel: 'RCS basic' },
        { flag: 'true', body: 'a' * 158, image: false, link: true, channel: 'RCS single 4521' }
      ].each do |example|
        description = "programme une campagne #{example[:channel]} pour un message de #{example[:body].bytesize} octets " \
                      "#{example[:image] ? 'avec' : 'sans'} image, #{example[:link] ? 'avec' : 'sans'} lien, " \
                      "interrupteur #{example[:flag].inspect}"

        it description do
          campaigns = []
          stub_spot_hit_campaigns(campaigns)
          bundle = FactoryBot.create(:media_text_messages_bundle, body1: 'Bonjour !', body2: example[:body], body3: nil)
          bundle.update_columns(
            rcs_media2_id: example[:image] ? 3310 : 4521,
            image2_id: example[:image] ? FactoryBot.create(:media_image).id : nil,
            link2_id: example[:link] ? FactoryBot.create(:medium, url: 'https://1001mots.org').id : nil
          )

          service = with_rcs_single_text(example[:flag]) { program_module_with(bundle) }

          expect(service.errors).to be_empty
          expect(channel_of(campaign_for(campaigns, example[:body]))).to eq(example[:channel])
        end
      end
    end

    context 'quand RCS_SINGLE_TEXT_ENABLED est absent' do
      it 'envoie en SMS un message long sans image sans transmettre son modèle texte' do
        campaigns = []
        stub_spot_hit_campaigns(campaigns)
        bundle = FactoryBot.create(:media_text_messages_bundle, body1: 'Bonjour !', body2: 'a' * 300, body3: nil)
        bundle.update_column(:rcs_media2_id, 4521)

        with_rcs_single_text(nil) { program_module_with(bundle) }

        expect(channel_of(campaign_for(campaigns, 'a' * 300))).to eq('SMS')
        expect(campaigns.pluck('media_id')).not_to include('4521')
      end
    end

    context 'quand un message long sans image part en RCS single texte' do
      it 'transmet en secours le texte complet et la valeur de chaque variable' do
        campaigns = []
        stub_spot_hit_campaigns(campaigns)
        body = "1001mots : cette semaine, chantez une comptine avec {PRENOM_ENFANT} pendant le bain.\n" \
               "Pour qu'elle s'en souvienne, reprenez-la chaque soir au coucher, en douceur, avec ses gestes préférés."
        bundle = FactoryBot.create(:media_text_messages_bundle, body1: body, body2: nil, body3: nil)
        bundle.update_column(:rcs_media1_id, 4521)

        with_rcs_single_text('true') { program_module_with(bundle) }

        campaign = campaign_for(campaigns, '1001mots : cette semaine')
        expect(channel_of(campaign)).to eq('RCS single 4521')
        expect(campaign['fallback_message']).to eq(body)
        expect(campaign['custom_list_with_data'].values.first['PRENOM_ENFANT']).to eq('Léa')
      end
    end

    context "quand une image a été ajoutée mais que Spot-Hit a refusé le modèle carte" do
      it 'programme le message en RCS single avec le modèle texte conservé' do
        campaigns = []
        stub_spot_hit_campaigns(campaigns)
        bundle = FactoryBot.create(:media_text_messages_bundle, body1: 'a' * 300, body2: nil, body3: nil)
        bundle.update_columns(image1_id: FactoryBot.create(:media_image).id, rcs_media1_id: 4521, rcs_text_template1: true)

        with_rcs_single_text('true') { program_module_with(bundle) }

        expect(channel_of(campaign_for(campaigns, 'a' * 300))).to eq('RCS single 4521')
      end
    end

    context "quand un message long sans image n'a pas de modèle et que RCS_SINGLE_TEXT_ENABLED est actif" do
      it 'envoie le message en SMS et signale le trio sans modèle à Rollbar' do
        campaigns = []
        stub_spot_hit_campaigns(campaigns)
        allow(Rollbar).to receive(:error)
        bundle = FactoryBot.create(:media_text_messages_bundle, body1: 'a' * 220, body2: nil, body3: nil)
        bundle.update_column(:rcs_media1_id, nil)

        service = with_rcs_single_text('true') { program_module_with(bundle) }

        expect(service.errors).to be_empty
        expect(channel_of(campaign_for(campaigns, 'a' * 220))).to eq('SMS')
        expect(Rollbar).to have_received(:error).with(
          'SupportModule::ProgramService',
          hash_including(text_messages_bundle_id: bundle.id, message_index: 1)
        )
      end
    end
  end
end
