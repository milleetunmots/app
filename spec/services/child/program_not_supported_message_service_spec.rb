require 'rails_helper'

RSpec.describe Child::ProgramNotSupportedMessageService do
  def campaigns
    WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                            .select { |signature| signature.uri.path.start_with?('/api/envoyer/') }
                            .map { |signature| URI.decode_www_form(signature.body).to_h }
  end

  def scheduled_at(campaign)
    campaign['date'].match?(/\A\d+\z/) ? Time.zone.at(campaign['date'].to_i) : Time.zone.parse(campaign['date'])
  end

  def not_supported_bundle(link: nil)
    FactoryBot.create(:media_text_messages_bundle, name: 'Message de non-accompagnement', body1: 'Voici nos conseils : {URL}', body2: nil, body3: nil, link1: link)
              .tap { |bundle| bundle.update_column(:key, 'non_accompagnement') }
  end

  def ines
    FactoryBot.create(:child, first_name: 'Inès', group_status: 'not_supported').tap { WebMock::RequestRegistry.instance.reset! }
  end

  around { |example| travel_to(Time.zone.parse('2027-03-02 10:00')) { example.run } }

  it "programme pour le parent d'Inès, 3 jours plus tard à 12 h 30, le texte du trio avec son lien" do
    video = FactoryBot.create(:media_video, name: 'Conseils langage')
    not_supported_bundle(link: video)
    child = ines

    service = described_class.new(child).call

    expect(service.errors).to be_empty
    expect(campaigns.size).to eq(1)
    expect(campaigns.first['fallback_message'] || campaigns.first['message']).to start_with('Voici nos conseils : ')
    expect(scheduled_at(campaigns.first)).to eq(Time.zone.parse('2027-03-05 12:30'))
    expect(RedirectionUrl.find_by(parent: child.parent1).redirection_target.medium).to eq(video)
  end

  it 'ne programme rien et signale le nom et la clé quand le trio est introuvable' do
    service = described_class.new(ines).call

    expect(campaigns).to be_empty
    expect(service.errors).to contain_exactly(a_string_including('Message de non-accompagnement', 'non_accompagnement'))
  end

  it "ne programme rien et signale que le trio n'a pas de lien" do
    not_supported_bundle

    service = described_class.new(ines).call

    expect(campaigns).to be_empty
    expect(service.errors).to contain_exactly(a_string_including('Message de non-accompagnement', "n'a pas de lien"))
  end
end
