require 'rails_helper'

RSpec.describe ChildSupport::SendCallGoalsMessagesService do
  def stub_spot_hit_campaigns(campaigns)
    stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').to_return do |request|
      campaigns << Rack::Utils.parse_nested_query(request.body).merge('endpoint' => 'rcs')
      { status: 200, body: { success: true, campaign_id: '123' }.to_json }
    end
    stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/sms').to_return do |request|
      campaigns << Rack::Utils.parse_nested_query(request.body).merge('endpoint' => 'sms')
      { status: 200, body: {}.to_json }
    end
  end

  def with_env(values)
    previous = values.keys.index_with { |key| ENV.fetch(key, nil) }
    values.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  def long_body
    "Cette semaine, racontez une histoire. #{'a' * 212}"
  end

  def program_call3_bundle_for_lea(rcs_single_text_enabled:)
    bundle = FactoryBot.create(:media_text_messages_bundle, name: 'Après appel 3 — semaine 1', body1: 'Bonjour !', body2: long_body, body3: nil)
    bundle.update_column(:rcs_media2_id, 4521)
    group = FactoryBot.create(:group, started_at: 25.weeks.ago.to_date.prev_occurring(:monday))
    child = FactoryBot.create(:child, first_name: 'Léa', group: group, group_status: 'active')
    FactoryBot.create(:child_support, current_child: child, call3_goals_sms: 'Lire une histoire chaque soir')

    with_env('RCS_SINGLE_TEXT_ENABLED' => rcs_single_text_enabled, 'CALL3_TEXT_MESSAGES_BUNDLES' => 'Après appel 3 — semaine 1') do
      ChildSupport::SendCallGoalsMessagesService.new(group.id, 3).call
    end
  end

  describe '#call' do
    context "pour un trio envoyé après l'appel 3 dont un message sans image dépasse 160 octets" do
      it 'le programme en RCS single texte avec son modèle quand RCS_SINGLE_TEXT_ENABLED est actif' do
        campaigns = []
        stub_spot_hit_campaigns(campaigns)

        program_call3_bundle_for_lea(rcs_single_text_enabled: 'true')

        campaign = campaigns.find { |c| c['fallback_message'].to_s.start_with?(long_body) }
        expect(campaign).to include('endpoint' => 'rcs', 'rcs_type' => 'single', 'media_id' => '4521')
      end

      it 'le programme en SMS sans transmettre son modèle quand RCS_SINGLE_TEXT_ENABLED est absent' do
        campaigns = []
        stub_spot_hit_campaigns(campaigns)

        program_call3_bundle_for_lea(rcs_single_text_enabled: nil)

        expect(campaigns.find { |c| c['message'].to_s.start_with?(long_body) }).to include('endpoint' => 'sms')
        expect(campaigns.pluck('media_id')).not_to include('4521')
      end
    end
  end
end
