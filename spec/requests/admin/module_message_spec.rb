require 'rails_helper'

RSpec.describe 'Programmation manuelle des messages d\'un module', type: :request do
  def with_rcs_single_text(value)
    previous = ENV.fetch('RCS_SINGLE_TEXT_ENABLED', nil)
    ENV['RCS_SINGLE_TEXT_ENABLED'] = value
    yield
  ensure
    previous.nil? ? ENV.delete('RCS_SINGLE_TEXT_ENABLED') : ENV['RCS_SINGLE_TEXT_ENABLED'] = previous
  end

  def campaigns
    WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                            .select { |signature| signature.uri.path.start_with?('/api/envoyer/') }
                            .map { |signature| Rack::Utils.parse_nested_query(signature.body).merge('endpoint' => signature.uri.path) }
  end

  def module_with_text_template(body2)
    bundle = FactoryBot.create(:media_text_messages_bundle, name: 'Comptines', body1: 'Bonjour !', body2: body2, body3: nil)
    bundle.update_columns(rcs_media2_id: 4521, rcs_text_template2: true)
    support_module = FactoryBot.create(:support_module, name: 'Comptines')
    FactoryBot.create(:support_module_week, support_module: support_module, medium: bundle, position: 1)
    WebMock::RequestRegistry.instance.reset!
    support_module
  end

  def program(support_module, submitted_body)
    child = FactoryBot.create(:child, first_name: 'Léa', group: FactoryBot.create(:group), group_status: 'active')
    post '/admin/messages/program_module_message', params: {
      module_to_send: support_module.id,
      recipients: "[\"parent.#{child.parent1_id}\"]",
      'body_support_module_week_1_message_2' => submitted_body,
      'planned_date_support_module_week_1_message_2' => Time.zone.tomorrow.iso8601,
      'planned_hour_support_module_week_1_message_2' => '12:30'
    }
  end

  before { sign_in FactoryBot.create(:admin_user, user_role: 'super_admin') }

  long_body = "Chantez une comptine avec votre enfant ce soir.\nRépétez-la demain matin.\n#{'a' * 220}"
  short_body = 'Chantez une comptine avec votre enfant ce soir.'

  [
    { body: long_body, submitted: long_body, endpoint: '/api/envoyer/rcs', rcs_type: 'single', media_id: '4521', sent: :trio,
      label: 'sans toucher au texte' },
    { body: long_body, submitted: long_body.gsub("\n", "\r\n"), endpoint: '/api/envoyer/rcs', rcs_type: 'single', media_id: '4521', sent: :trio,
      label: 'sans toucher au texte, renvoyé avec des fins de ligne \r\n' },
    { body: long_body, submitted: long_body.sub('comptine', 'berceuse'), endpoint: '/api/envoyer/sms', sent: :submitted,
      label: 'après avoir remplacé « comptine » par « berceuse »' },
    { body: short_body, submitted: short_body.sub('comptine', 'berceuse'), endpoint: '/api/envoyer/rcs', rcs_type: 'basic', sent: :submitted,
      label: 'court, après avoir remplacé « comptine » par « berceuse »' },
    { body: short_body, submitted: short_body, endpoint: '/api/envoyer/rcs', rcs_type: 'basic', sent: :trio,
      label: 'court, sans toucher au texte' }
  ].each do |example|
    it "programme le message 2 sans image d'après le trio quand il est envoyé #{example[:label]}" do
      support_module = module_with_text_template(example[:body])

      with_rcs_single_text('true') { program(support_module, example[:submitted]) }

      campaign = campaigns.find { |c| c['endpoint'] == example[:endpoint] }
      expected_text = example[:sent] == :trio ? example[:body] : example[:submitted]
      expect(campaign).to include('rcs_type' => example[:rcs_type]) if example[:rcs_type]
      expect(campaign['media_id']).to eq(example[:media_id])
      expect(campaign['fallback_message'] || campaign['message']).to eq(expected_text)
    end
  end

  context 'quand le message 1 a une image et le modèle carte 3310' do
    def module_with_card_template
      bundle = FactoryBot.create(:media_text_messages_bundle, name: 'Comptines', body1: 'Regardez cette comptine en vidéo.', body2: 'À demain !', body3: nil)
      bundle.update_columns(image1_id: FactoryBot.create(:media_image).id, rcs_media1_id: 3310, rcs_text_template1: false)
      support_module = FactoryBot.create(:support_module, name: 'Comptines')
      FactoryBot.create(:support_module_week, support_module: support_module, medium: bundle, position: 1)
      WebMock::RequestRegistry.instance.reset!
      support_module
    end

    it "affiche le texte du message avec image sans qu'il puisse être modifié, et celui du message sans image modifiable" do
      support_module = module_with_card_template

      get '/admin/messages', params: { module_to_send: support_module.id, planned_date: Time.zone.today.next_occurring(:tuesday).iso8601, recipients: '[]' }

      page = Nokogiri::HTML(response.body)
      expect(page.at_css('textarea[name="body_support_module_week_1_message_1"]')['readonly']).to be_present
      expect(page.at_css('textarea[name="body_support_module_week_1_message_2"]')['readonly']).to be_nil
      expect(page.at_css('input[name="rcs_media_support_module_week_1_message_1"]')).to be_nil
    end

    it 'programme le texte du trio avec son image et son modèle, même si la requête envoie un autre texte' do
      support_module = module_with_card_template
      child = FactoryBot.create(:child, first_name: 'Léa', group: FactoryBot.create(:group), group_status: 'active')

      post '/admin/messages/program_module_message', params: {
        module_to_send: support_module.id,
        recipients: "[\"parent.#{child.parent1_id}\"]",
        'body_support_module_week_1_message_1' => 'Texte forcé',
        'planned_date_support_module_week_1_message_1' => Time.zone.tomorrow.iso8601,
        'planned_hour_support_module_week_1_message_1' => '12:30'
      }

      campaign = campaigns.find { |c| c['endpoint'] == '/api/envoyer/rcs' }
      expect(campaign).to include('rcs_type' => 'single', 'media_id' => '3310', 'fallback_message' => 'Regardez cette comptine en vidéo.')
    end
  end
end
