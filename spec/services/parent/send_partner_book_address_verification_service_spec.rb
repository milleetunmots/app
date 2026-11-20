require 'rails_helper'

RSpec.describe Parent::SendPartnerBookAddressVerificationService do
  bundle_name = "Vérification de l'adresse pour le livre offert par un partenaire"

  def campaigns
    WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                            .select { |signature| signature.uri.path.start_with?('/api/envoyer/') }
                            .map { |signature| CGI.unescape(signature.body) }
  end

  def partner_book_bundle
    FactoryBot.create(:media_text_messages_bundle, name: "Vérification de l'adresse pour le livre offert par un partenaire",
                                                   body1: 'Livre pour {PRENOM_ENFANT} à : {PARENT_ADDRESS}', body2: nil, body3: nil)
              .tap { |bundle| bundle.update_column(:key, 'verification_adresse_livre_partenaire') }
  end

  def lea_hugo_and_ines
    lea = FactoryBot.create(:child, first_name: 'Léa')
    hugo = FactoryBot.create(:child, first_name: 'Hugo')
    ines = FactoryBot.create(:child, first_name: 'Inès', parent1: hugo.parent1)
    WebMock::RequestRegistry.instance.reset!
    [lea, hugo, ines]
  end

  def claire(saturated: false)
    FactoryBot.create(:admin_user, user_role: 'contributor', name: 'Claire').tap do |admin_user|
      FactoryBot.create(:sms_send_record, admin_user: admin_user, recipients_count: 50) if saturated
    end
  end

  it 'envoie une fois à chaque parent le texte du trio avec son adresse et décompte 2 destinataires du quota' do
    partner_book_bundle
    children = lea_hugo_and_ines
    admin_user = claire

    service = described_class.new(child_ids: children.map(&:id), admin_user: admin_user).call

    expect(service.errors).to be_empty
    expect(campaigns.size).to eq(1)
    expect(campaigns.first).to include(children[0].parent1.phone_number.delete_prefix('0'), children[1].parent1.address, children[0].parent1.address)
    expect(admin_user.sms_send_records.not_blocked.sum(:recipients_count)).to eq(2)
  end

  it "n'envoie rien, ne décompte rien et signale le nom et la clé quand le trio est introuvable" do
    children = lea_hugo_and_ines
    admin_user = claire
    expect(Rollbar).to receive(:error).with(a_string_including(bundle_name, 'verification_adresse_livre_partenaire'))

    service = described_class.new(child_ids: [children[0].id], admin_user: admin_user).call

    expect(campaigns).to be_empty
    expect(service.errors).to contain_exactly("Trio introuvable : « #{bundle_name} » (clé verification_adresse_livre_partenaire), message non envoyé")
    expect(admin_user.sms_send_records.not_blocked.sum(:recipients_count)).to eq(0)
  end

  it 'renvoie le message de quota quand le quota est atteint et le trio introuvable' do
    children = lea_hugo_and_ines

    service = described_class.new(child_ids: [children[0].id], admin_user: claire(saturated: true)).call

    expect(campaigns).to be_empty
    expect(service.errors).to contain_exactly(SmsSendRecord::QuotaGuard::QUOTA_EXCEEDED_MESSAGE)
  end
end
