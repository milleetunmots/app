require 'rails_helper'

RSpec.describe SpotHit::CreateRcsModelService do
  let(:text_messages_bundle) { FactoryBot.create(:media_text_messages_bundle) }
  let(:image) { FactoryBot.create(:media_image) }
  let(:message_index) { 1 }

  before do
    # skip spotHit upload callback
    allow_any_instance_of(Media::Image).to receive(:upload_file_to_spot_hit)

    text_messages_bundle.update(
      body1: "Ceci est un message de test\nAvec plusieurs lignes",
      image1_id: image.id
    )

    stub_request(:post, "https://www.spot-hit.fr/api/rcs/model/create")
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
      it 'creates an RCS template successfully' do
        expect(service.errors).to be_empty
        expect(service.rcs_media_id).to eq(12345)
      end

      it 'saves the RCS media ID to the bundle' do
        service
        expect(text_messages_bundle.reload.rcs_media1_id).to eq(12345)
      end

      it 'sends the correct request to SpotHit API' do
        service

        expect(WebMock).to have_requested(:post, "https://www.spot-hit.fr/api/rcs/model/create")
          .with { |req|
            req.body.include?('key') &&
            req.body.include?('model') &&
            req.body.include?('Ceci est un message de test')
          }
      end
    end

    context 'with invalid message_index' do
      let(:message_index) { 5 }

      it 'returns an error' do
        expect(service.errors).to include("message_index must be 1, 2, or 3")
        expect(service.rcs_media_id).to be_nil
      end

      it 'does not save anything to the bundle' do
        service
        expect(text_messages_bundle.reload.rcs_media1_id).to be_nil
      end
    end

    context 'when body is blank' do
      before do
        text_messages_bundle.update(body1: nil)
      end

      it 'returns an error' do
        expect(service.errors).to include("body1 is blank, cannot create RCS template")
        expect(service.rcs_media_id).to be_nil
      end
    end

    context 'when image is missing' do
      before do
        text_messages_bundle.update(image1_id: nil)
      end

      it 'adds a warning but still processes' do
        expect(service.errors).to include("image1 is blank, cannot create RCS template")
      end
    end

    context 'when SpotHit API returns an error' do
      before do
        stub_request(:post, "https://www.spot-hit.fr/api/rcs/model/create")
          .to_return(
            status: 200,
            body: { success: false, error: { message: "Invalid template" } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'captures the error' do
        expect(service.errors).to include(/Erreur lors de la création du modèle RCS/)
        expect(service.rcs_media_id).to be_nil
      end

      it 'does not save anything to the bundle' do
        service
        expect(text_messages_bundle.reload.rcs_media1_id).to be_nil
      end
    end

    context 'with message_index 2' do
      let(:message_index) { 2 }

      before do
        text_messages_bundle.update(
          body2: "Second message",
          image2_id: image.id
        )
      end

      it 'saves to rcs_media2_id' do
        service
        expect(text_messages_bundle.reload.rcs_media2_id).to eq(12345)
        expect(text_messages_bundle.rcs_media1_id).to be_nil
      end
    end

    context 'with message_index 3' do
      let(:message_index) { 3 }

      before do
        text_messages_bundle.update(
          body3: "Third message",
          image3_id: image.id
        )
      end

      it 'saves to rcs_media3_id' do
        service
        expect(text_messages_bundle.reload.rcs_media3_id).to eq(12345)
        expect(text_messages_bundle.rcs_media1_id).to be_nil
      end
    end

    context 'with custom rcs_title1' do
      before do
        text_messages_bundle.update(rcs_title1: 'Mon titre personnalisé')
      end

      it 'uses the custom title in the API request' do
        service

        expect(WebMock).to have_requested(:post, "https://www.spot-hit.fr/api/rcs/model/create")
          .with { |req|
            req.body.force_encoding('UTF-8').include?('Mon titre personnalisé')
          }
      end
    end

    context 'without rcs_title1' do
      before do
        text_messages_bundle.update(rcs_title1: nil)
      end

      it 'uses "1001mots" as default title in the API request' do
        service

        expect(WebMock).to have_requested(:post, "https://www.spot-hit.fr/api/rcs/model/create")
          .with { |req|
            req.body.include?('1001mots')
          }
      end
    end

    context 'with empty rcs_title1' do
      before do
        text_messages_bundle.update(rcs_title1: '')
      end

      it 'uses "1001mots" as default title in the API request' do
        service

        expect(WebMock).to have_requested(:post, "https://www.spot-hit.fr/api/rcs/model/create")
          .with { |req|
            req.body.include?('1001mots')
          }
      end
    end

    context 'with message_index 2 and custom rcs_title2' do
      let(:message_index) { 2 }

      before do
        text_messages_bundle.update(
          body2: "Second message",
          image2_id: image.id,
          rcs_title2: 'Titre du message 2'
        )
      end

      it 'uses rcs_title2 for message 2' do
        service

        expect(WebMock).to have_requested(:post, "https://www.spot-hit.fr/api/rcs/model/create")
          .with { |req|
            req.body.force_encoding('UTF-8').include?('Titre du message 2')
          }
      end
    end
  end
end
