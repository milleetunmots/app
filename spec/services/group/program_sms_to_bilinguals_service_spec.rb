require 'rails_helper'

RSpec.describe Group::ProgramSmsToBilingualsService do
  def campaigns
    WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                            .select { |signature| signature.uri.path.start_with?('/api/envoyer/') }
                            .map { |signature| Rack::Utils.parse_nested_query(signature.body) }
  end

  def bilingual_bundle(key:, body:, link: nil)
    bundle = FactoryBot.create(:media_text_messages_bundle, name: "Bilingue #{key}", body1: body, body2: nil, body3: nil)
    bundle.update_columns(key: key, link1_id: link&.id)
    bundle
  end

  def lea_bilingual_group
    group = FactoryBot.create(:group)
    child = FactoryBot.create(:child, first_name: 'Léa', group: group, group_status: 'active')
    FactoryBot.create(:child_support, current_child: child, is_bilingual: '0_yes')
    WebMock::RequestRegistry.instance.reset!
    group
  end

  let(:first_sms_date) { Date.new(Time.zone.today.year + 1, 3, 2) }

  it 'programme les trois messages d’après leurs trios, à J0, J+7 avec le lien de la vidéo et J+14' do
    video = FactoryBot.create(:media_video, name: 'URLrecFSkjakLY8MWEvG')
    bilingual_bundle(key: 'bilingues_j0', body: 'Parlez votre langue.')
    bilingual_bundle(key: 'bilingues_j7', body: 'Regardez cette vidéo : {URL}', link: video)
    bilingual_bundle(key: 'bilingues_j14', body: 'Et chez vous, quelle langue ?')
    group = lea_bilingual_group

    described_class.new(group.id, first_sms_date).call

    sent = campaigns.to_h { |form| [form['fallback_message'] || form['message'], form['date'].to_s[0, 10]] }
    expect(sent).to eq(
      'Parlez votre langue.' => first_sms_date.strftime('%Y-%m-%d'),
      'Regardez cette vidéo : {URL}' => (first_sms_date + 7).strftime('%Y-%m-%d'),
      'Et chez vous, quelle langue ?' => (first_sms_date + 14).strftime('%Y-%m-%d')
    )
    expect(RedirectionTarget.find_by(medium: video)).to be_present
  end

  it "n'envoie aucun des trois messages et signale le trio manquant quand l'un d'eux est introuvable" do
    allow(Rollbar).to receive(:error)
    bilingual_bundle(key: 'bilingues_j0', body: 'Parlez votre langue.')
    bilingual_bundle(key: 'bilingues_j14', body: 'Et chez vous, quelle langue ?')
    group = lea_bilingual_group

    described_class.new(group.id, first_sms_date).call

    expect(campaigns).to be_empty
    expect(Rollbar).to have_received(:error).with(a_string_including('bilingues_j7'), group_id: group.id)
  end
end
