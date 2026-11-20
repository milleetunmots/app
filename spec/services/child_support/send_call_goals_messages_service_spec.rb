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

  describe "trios envoyés après l'appel 3" do
    def call3_family
      group = FactoryBot.create(:group, started_at: Date.new(2027, 1, 4))
      child = FactoryBot.create(:child, first_name: 'Léa', group: group, group_status: 'active')
      child.child_support.update_columns(call3_goals_sms: 'Lire une histoire chaque soir')
      group
    end

    it 'programme les trios trouvés à leur semaine et signale une seule fois le trio introuvable' do
      FactoryBot.create(:media_text_messages_bundle, name: 'Après appel 3 — semaine 2', body1: 'Semaine 2', body2: nil, body3: nil)
      group = call3_family
      FactoryBot.create(:child, first_name: 'Hugo', group: group, group_status: 'active').child_support.update_columns(call3_goals_sms: 'Chanter')
      campaigns = []
      stub_spot_hit_campaigns(campaigns)

      service = with_env('CALL3_TEXT_MESSAGES_BUNDLES' => 'Après appel 3 — absent, Après appel 3 — semaine 2') { described_class.new(group.id, 3).call }

      expect(campaigns.pluck('message', 'fallback_message').flatten.compact).to eq(['Semaine 2', 'Semaine 2'])
      expect(service.errors.flatten).to eq(["Trio introuvable : « Après appel 3 — absent », message d'après l'appel 3 non envoyé"])
    end

    it "ne plante pas et n'envoie rien quand la liste des trios n'est pas configurée" do
      group = call3_family

      service = with_env('CALL3_TEXT_MESSAGES_BUNDLES' => nil) { described_class.new(group.id, 3).call }

      expect(service.errors.flatten).to be_empty
    end
  end

  describe 'rappel de petite mission lu dans son trio' do
    def goals_sms(link)
      "Bonjour, Voici votre petite mission :\r\nLire une histoire chaque soir\r\nQuand vous aurez essayé, dites-le-moi : #{link}"
    end

    def child_support_with_mission(call_index, link)
      group = FactoryBot.create(:group, started_at: Date.new(2027, 1, 4))
      child = FactoryBot.create(:child, first_name: 'Léa', group: group, group_status: 'active')
      child.child_support.update_columns("call#{call_index}_goals_sms" => goals_sms(link), call1_previous_goals_follow_up: '3_no_tried')
      child.child_support
    end

    [
      [0, 'Rappel de petite mission — 2 semaines', 'rappel_mission_deux_semaines', '18-01-2027', 'https://form.1001mots.org/c0?st=abc'],
      [3, 'Rappel de petite mission — appel 3', 'rappel_mission_appel3', '28-06-2027', 'https://form.1001mots.org/c3?st=abc']
    ].each do |call_index, name, key, date, link|
      it "envoie le texte du trio « #{name} », avec la petite mission et le lien de suivi" do
        FactoryBot.create(:media_text_messages_bundle, name: name, body1: "Texte du trio #{name}", body2: nil, body3: nil).update_column(:key, key)
        child_support = child_support_with_mission(call_index, link)
        expect(ProgramAutomaticMessageService).to receive(:new).with(
          date, '12:30', ["parent.#{child_support.parent1.id}"], "Texte du trio #{name}", nil, nil,
          automatic_message_key: key,
          recipient_variables: { child_support.parent1.id => { 'PETITE_MISSION' => 'Lire une histoire chaque soir', 'LIEN_SUIVI_PETITE_MISSION' => link } }
        ).and_call_original

        with_env('CALL3_TEXT_MESSAGES_BUNDLES' => '') { described_class.new(child_support.current_child.group_id, call_index).call }
      end

      it "n'envoie rien et signale le trio « #{name} » introuvable" do
        child_support = child_support_with_mission(call_index, link)
        expect(ProgramAutomaticMessageService).not_to receive(:new)

        service = with_env('CALL3_TEXT_MESSAGES_BUNDLES' => '') { described_class.new(child_support.current_child.group_id, call_index).call }

        expect(service.errors).to include(Media::TextMessagesBundle.missing_message(name: name, key: key))
      end
    end
  end
end
