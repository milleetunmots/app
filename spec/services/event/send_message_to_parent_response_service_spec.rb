require 'rails_helper'

RSpec.describe Event::SendMessageToParentResponseService do
  def campaigns
    WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                            .select { |signature| signature.uri.path.start_with?('/api/envoyer/') }
                            .map { |signature| URI.decode_www_form(signature.body).to_h.merge('raw' => signature.body) }
  end

  def paul(with_supporter: true)
    @paul ||= begin
      lucas = FactoryBot.create(:child, first_name: 'Lucas', group: FactoryBot.create(:group), group_status: 'active')
      marie = FactoryBot.create(:admin_user, user_role: 'caller', name: 'Marie', aircall_phone_number: '0189000001') if with_supporter
      lucas.child_support.update!(supporter: marie)
      lucas.parent1
    end
  end

  def reply_received(at:, key: 'numero_sans_sms')
    FactoryBot.create(:text_message, related: paul, originated_by_app: true, message_provider: 'spot_hit', occurred_at: Time.zone.parse(at),
                                     body: "1001mots: Ce numéro ne peut pas recevoir de SMS. Pour nous contacter, merci d'envoyer vos messages " \
                                           'directement à Marie au 0189000001. Merci!',
                                     automatic_message_key: key)
  end

  def paul_sends_sms(at)
    WebMock::RequestRegistry.instance.reset!
    travel_to(Time.zone.parse(at)) { described_class.new(paul.phone_number).call }
  end

  describe 'fenêtre de 24 heures après la dernière réponse automatique' do
    [
      ['2027-03-02 09:00', 0],
      ['2027-03-02 10:00', 0],
      ['2027-03-02 11:00', 1]
    ].each do |moment, expected_count|
      it "envoie #{expected_count} réponse quand Paul écrit le #{moment}, après une réponse reçue le 1er mars à 10 h" do
        reply_received(at: '2027-03-01 10:00')

        service = paul_sends_sms(moment)

        expect(service.errors).to be_empty
        expect(campaigns.size).to eq(expected_count)
      end
    end
  end

  [
    ['le texte de la réponse envoyé à la main par Marie depuis la page Message', nil],
    ['la réponse automatique, envoyée avant le déploiement', nil]
  ].each do |description, key|
    it "répond à Paul qui a reçu #{description}, sans clé de message automatique, et garde la clé de la réponse" do
      reply_received(at: '2027-03-02 09:00', key: key)

      service = paul_sends_sms('2027-03-02 10:00')

      expect(service.errors).to be_empty
      expect(campaigns.size).to eq(1)
      expect(paul.events.text_messages.order(:id).last.automatic_message_key).to eq('numero_sans_sms')
    end
  end

  it "ne répond pas et n'alerte pas quand l'enfant n'a pas d'accompagnante" do
    paul(with_supporter: false)

    service = paul_sends_sms('2027-03-02 10:00')

    expect(campaigns).to be_empty
    expect(service.errors).to be_empty
  end
end
