require 'rails_helper'

RSpec.describe Parent::ProgramSmsToVerifyAddressService do
  let(:group) { FactoryBot.create(:group) }
  let(:lea) { FactoryBot.create(:child, first_name: 'Léa', group: group, group_status: 'active', should_contact_parent1: true) }
  let(:date) { Time.zone.parse('2027-01-11 13:00') }

  before do
    lea.parent1.update!(book_delivery_location: 'home', letterbox_name: 'Martin', address: '3 rue des Lilas', address_supplement: nil,
                        postal_code: '75011', city_name: 'Paris')
  end

  it "envoie le texte du trio, avec l'adresse sur plusieurs lignes et le prénom de l'enfant" do
    FactoryBot.create(:media_text_messages_bundle, name: "Vérification de l'adresse", body1: "Adresse :\n{PARENT_ADDRESS}\nFin", body2: nil, body3: nil)
              .update_column(:key, 'verification_adresse')
    expect(ProgramAutomaticMessageService).to receive(:new).with(
      '11-01-2027', '13:00', ["parent.#{lea.parent1_id}"], "Adresse :\n{PARENT_ADDRESS}\nFin", nil, nil,
      automatic_message_key: 'verification_adresse',
      recipient_variables: { lea.parent1_id => { 'PARENT_ADDRESS' => "\nMartin\n3 rue des Lilas\n75011 Paris", 'PRENOM_ENFANT' => 'Léa' } }
    ).and_call_original

    service = described_class.new(group.id, date).call

    expect(service.errors).to be_empty
  end

  it "n'envoie rien et signale le trio introuvable" do
    lea
    expect(ProgramAutomaticMessageService).not_to receive(:new)

    service = described_class.new(group.id, date).call

    expect(service.errors).to include("Trio introuvable : « Vérification de l'adresse » (clé verification_adresse), message non envoyé")
  end
end
