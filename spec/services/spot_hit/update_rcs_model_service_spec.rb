require 'rails_helper'

RSpec.describe SpotHit::UpdateRcsModelService do
  let(:image) { FactoryBot.create(:media_image) }
  let(:message_index) { 1 }
  let(:text_messages_bundle) do
    messages = FactoryBot.create(:media_text_messages_bundle)
    messages.update_columns(
      body1: "Ceci est un message de test\nAvec plusieurs lignes",
      image1_id: image.id,
      rcs_media1_id: 12345
    )
    messages.reload
  end

  before(:each) do
    stub_request(:post, "https://www.spot-hit.fr/api/rcs/model/modify")
      .to_return(
        status: 200,
        body: { success: true, id: 12345 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe '#call' do
    subject(:service) do
      described_class.new(
        text_messages_bundle: text_messages_bundle,
        message_index: message_index
      ).call
    end

    context 'with valid params' do
      it 'modifie le modèle RCS avec succès' do
        expect(service.errors).to be_empty

        expect(WebMock).to have_requested(:post, "https://www.spot-hit.fr/api/rcs/model/modify")
      end
    end

    # Régression : UpdateRcsModelService hérite de CreateRcsModelService mais
    # redéfinissait `call` sans appeler `check_template_content`. Un template
    # propre pouvait donc être édité après coup pour y mettre du contenu
    # interdit, sans jamais repasser par le guard d'envoi (le contenu riche
    # part tel quel à chaque envoi RCS).
    context "quand le contenu édité contient un terme interdit" do
      before do
        FactoryBot.create(:blocked_pattern, value: 'virement bancaire')
        text_messages_bundle.update_columns(body1: 'Merci de faire un virement bancaire rapidement')
        text_messages_bundle.reload
      end

      around do |example|
        previous = ENV['KEYWORD_FILTER_BLOCKING_ENABLED']
        ENV['KEYWORD_FILTER_BLOCKING_ENABLED'] = 'true'
        example.run
        previous.nil? ? ENV.delete('KEYWORD_FILTER_BLOCKING_ENABLED') : ENV['KEYWORD_FILTER_BLOCKING_ENABLED'] = previous
      end

      it "refuse la modification, trace un BlockedSendAttempt et n'appelle pas SpotHit" do
        result = nil
        expect { result = service }.to change(BlockedSendAttempt, :count).by(1)

        expect(result.errors).to include('Ce message ne peut pas être envoyé, veuillez contacter le pôle tech.')
        expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/rcs/model/modify')
      end
    end

    context 'when rcs_media_id is missing' do
      before do
        text_messages_bundle.update_columns(rcs_media1_id: nil)
        text_messages_bundle.reload
      end

      it 'returns an error' do
        expect(service.errors).to include("rcs_media1_id is blank, cannot modify RCS template")
      end
    end
  end
end
