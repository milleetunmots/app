require 'rails_helper'

RSpec.describe ProgramAutomaticMessageService do
  def program(message, rcs_media_id = nil)
    described_class.new(
      Time.zone.today.strftime('%d-%m-%Y'), '12:30', ["parent.#{parent.id}"], message, rcs_media_id,
      automatic_message_key: 'numero_sans_sms'
    ).call
  end

  let(:parent) { FactoryBot.create(:child, group: FactoryBot.create(:group), group_status: 'active').parent1 }

  around { |example| travel_to(Time.zone.parse('2027-03-02 09:00')) { example.run } }

  it 'enregistre la clé du message automatique sur un message envoyé en SMS' do
    service = program("1001mots : #{'a' * 200}")

    expect(service.errors).to be_empty
    expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
    expect(parent.events.text_messages.last.automatic_message_key).to eq('numero_sans_sms')
  end

  it 'enregistre la clé du message automatique sur un message envoyé en RCS basic' do
    service = program('1001mots : Bonjour !')

    expect(service.errors).to be_empty
    expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').with(body: /rcs_type=basic/)
    expect(parent.events.text_messages.last.automatic_message_key).to eq('numero_sans_sms')
  end

  it 'enregistre la clé du message automatique sur un message envoyé en RCS single' do
    service = program("1001mots : #{'a' * 200}", 4522)

    expect(service.errors).to be_empty
    expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').with(body: /media_id=4522/)
    expect(parent.events.text_messages.last.automatic_message_key).to eq('numero_sans_sms')
  end

  it "garde la clé du message automatique dans l'envoi bloqué, pour le rejouer avec elle" do
    previous = ENV.fetch('URL_FILTER_BLOCKING_ENABLED', nil)
    ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'

    service = program('1001mots : Rejoignez-nous sur https://exemple-non-autorise.fr')

    expect(service.errors).not_to be_empty
    expect(BlockedSendAttempt.last.replay_params).to include('automatic_message_key' => 'numero_sans_sms')
  ensure
    ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
  end
end
