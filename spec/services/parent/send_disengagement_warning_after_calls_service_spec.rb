require 'rails_helper'

RSpec.describe Parent::SendDisengagementWarningAfterCallsService do
  def campaigns
    WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                            .select { |signature| signature.uri.path.start_with?('/api/envoyer/') }
                            .map { |signature| URI.decode_www_form(signature.body).to_h.merge('endpoint' => signature.uri.path, 'raw' => signature.body) }
  end

  def warning_bundle(name:, key:, body:)
    bundle = FactoryBot.create(:media_text_messages_bundle, name: name, body1: body, body2: nil, body3: nil)
    bundle.update_column(:key, key)
    bundle
  end

  def lucas_in_march_group(call_statuses)
    group = FactoryBot.create(:group, name: 'Mars')
    child = FactoryBot.create(:child, first_name: 'Lucas', group: group, group_status: 'active')
    child.child_support.update!(supporter: FactoryBot.create(:admin_user, user_role: 'caller', name: 'Marie'), **call_statuses)
    WebMock::RequestRegistry.instance.reset!
    [group, child]
  end

  around { |example| travel_to(Time.zone.parse('2027-03-02 10:00')) { example.run } }

  [
    { call_index: 0, statuses: { call0_status: 'KO' }, name: 'Après 1er KO · Appel 0', key: 'apres_premier_ko_appel0' },
    { call_index: 1, statuses: { call0_status: 'OK', call1_status: 'KO' }, name: 'Après 1er KO · Appel 1', key: 'apres_premier_ko_appel1' },
    { call_index: 2, statuses: { call0_status: 'OK', call1_status: 'OK', call2_status: 'KO' }, name: 'Après 1er KO · Appel 2', key: 'apres_premier_ko_appel2' }
  ].each do |example|
    it "envoie à 19 h le texte du trio « #{example[:name]} » au parent de Lucas, avec le prénom de son accompagnante" do
      warning_bundle(name: example[:name], key: example[:key], body: "{PRENOM_ACCOMPAGNANTE} a essayé de vous appeler (#{example[:name]}).")
      group, = lucas_in_march_group(example[:statuses])

      service = described_class.new(group.id, example[:call_index]).call

      expect(service.errors).to be_empty
      expect(campaigns.size).to eq(1)
      campaign = campaigns.first
      expect(campaign['fallback_message'] || campaign['message']).to eq("{PRENOM_ACCOMPAGNANTE} a essayé de vous appeler (#{example[:name]}).")
      expect(campaign['date']).to eq('2027-03-02 19:00:00')
      expect(campaign['raw']).to include('Marie')
    end
  end

  it "n'envoie rien et signale le nom et la clé quand le trio de l'appel est introuvable" do
    group, = lucas_in_march_group(call0_status: 'KO')

    service = described_class.new(group.id, 0).call

    expect(campaigns).to be_empty
    expect(service.errors).to include(a_string_including('Après 1er KO · Appel 0', 'apres_premier_ko_appel0'))
  end

  it 'programme une campagne RCS single avec le modèle et le lien du trio' do
    previous = ENV.fetch('RCS_SINGLE_TEXT_ENABLED', nil)
    ENV['RCS_SINGLE_TEXT_ENABLED'] = 'true'
    video = FactoryBot.create(:media_video, name: 'Pourquoi on vous appelle')
    bundle = warning_bundle(name: 'Après 1er KO · Appel 0', key: 'apres_premier_ko_appel0', body: "Marie a essayé de vous appeler. #{'a' * 200}")
    bundle.update_columns(link1_id: video.id, rcs_media1_id: 4521, rcs_text_template1: true)
    group, child = lucas_in_march_group(call0_status: 'KO')

    described_class.new(group.id, 0).call

    expect(campaigns.first).to include('endpoint' => '/api/envoyer/rcs', 'rcs_type' => 'single', 'media_id' => '4521')
    expect(RedirectionUrl.find_by(parent: child.parent1).redirection_target.medium).to eq(video)
  ensure
    previous.nil? ? ENV.delete('RCS_SINGLE_TEXT_ENABLED') : ENV['RCS_SINGLE_TEXT_ENABLED'] = previous
  end
end
