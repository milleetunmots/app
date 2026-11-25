require 'rails_helper'

RSpec.describe Parent::CheckAddressReminderService do
  def campaigns
    WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                            .select { |signature| signature.uri.path.start_with?('/api/envoyer/') }
                            .map { |signature| URI.decode_www_form(signature.body).to_h.merge('raw' => signature.body) }
  end

  def pnd_bundle
    FactoryBot.create(:media_text_messages_bundle, name: "Demande de vérification d'adresse (PND)",
                                                   body1: 'Vérifiez votre adresse : https://form.typeform.com/to/AbCd#st=xxxxx', body2: nil, body3: nil)
              .tap { |bundle| bundle.update_column(:key, 'verification_adresse_pnd') }
  end

  def sophie_with_suspected_address(*children_names)
    group = FactoryBot.create(:group)
    sophie = FactoryBot.create(:parent, first_name: 'Sophie')
    children_names.each { |name| FactoryBot.create(:child, first_name: name, parent1: sophie, group: group, group_status: 'active') }
    sophie.parent1_children.first.child_support.update!(address_suspected_invalid_at: Time.zone.parse('2027-03-02 10:00'))
    sophie
  end

  def address_request_sent(parent, at:, body: 'Vérifiez votre adresse : https://form.typeform.com/to/AbCd#st={PARENT_SECURITY_TOKEN}')
    FactoryBot.create(:text_message, related: parent, originated_by_app: true, message_provider: 'spot_hit', occurred_at: Time.zone.parse(at),
                                     body: body, automatic_message_key: 'verification_adresse_pnd')
    WebMock::RequestRegistry.instance.reset!
  end

  around { |example| travel_to(Time.zone.parse('2027-03-09 13:00')) { example.run } }

  it "envoie une seule relance, avec le texte du trio et son propre lien, au parent d'une fiche à deux enfants actifs" do
    pnd_bundle
    sophie = sophie_with_suspected_address('Emma', 'Noé')
    address_request_sent(sophie, at: '2027-03-02 10:00')

    service = described_class.new.call

    expect(service.errors).to be_empty
    expect(campaigns.size).to eq(1)
    expect(campaigns.first['fallback_message'] || campaigns.first['message'])
      .to eq('Vérifiez votre adresse : https://form.typeform.com/to/AbCd#st={PARENT_SECURITY_TOKEN}')
    expect(campaigns.first['raw']).to include(sophie.security_token)
    expect(sophie.events.text_messages.order(:id).last.automatic_message_key).to eq('verification_adresse_pnd')
  end

  it "n'envoie aucune relance au parent qui a reçu la demande il y a moins de 6 jours, même si le trio a été réécrit depuis" do
    pnd_bundle
    sophie = sophie_with_suspected_address('Emma')
    address_request_sent(sophie, at: '2027-03-04 10:00', body: 'Ancien texte : https://form.typeform.com/to/AbCd#st={PARENT_SECURITY_TOKEN}')

    service = described_class.new.call

    expect(service.errors).to be_empty
    expect(campaigns).to be_empty
  end

  it "signale l'échec de la relance avec l'identifiant de Sophie, sans son nom" do
    pnd_bundle
    sophie = sophie_with_suspected_address('Emma')
    address_request_sent(sophie, at: '2027-03-02 10:00')
    allow_any_instance_of(ProgramMessageService).to receive(:call).and_return(double(errors: ['SMS failed']))

    service = described_class.new.call

    expect(service.errors).to eq(["Address Verification message reminder not sent to parent #{sophie.id} : SMS failed"])
    expect(service.errors.join).not_to include(sophie.last_name)
  end

  it "n'envoie aucune relance et signale le nom et la clé quand le trio est introuvable" do
    sophie = sophie_with_suspected_address('Emma')
    address_request_sent(sophie, at: '2027-03-02 10:00')

    service = described_class.new.call

    expect(campaigns).to be_empty
    expect(service.errors).to eq(["Trio introuvable : « Demande de vérification d'adresse (PND) » (clé verification_adresse_pnd), message non envoyé"])
  end
end
