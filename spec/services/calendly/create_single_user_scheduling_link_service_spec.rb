require 'rails_helper'

RSpec.describe Calendly::CreateSingleUserSchedulingLinkService do
  let(:calendly_event_type_uri) { 'https://api.calendly.com/event_types/abc123' }
  let(:calendly_event_type_uris) { { 'call0' => calendly_event_type_uri, 'call1' => calendly_event_type_uri, 'call2' => calendly_event_type_uri, 'call3' => calendly_event_type_uri } }
  let(:admin_user) { FactoryBot.create(:admin_user, calendly_event_type_uris: calendly_event_type_uris) }
  let(:parent) { FactoryBot.create(:parent) }
  let(:child) { FactoryBot.create(:child, parent1: parent) }
  let(:child_support) { child.child_support }
  let(:call_session) { 2 }

  let(:booking_url) { 'https://calendly.com/d/xyz789' }
  let(:success_response) do
    {
      'resource' => {
        'booking_url' => booking_url,
        'owner' => calendly_event_type_uri,
        'owner_type' => 'EventType'
      }
    }
  end

  subject do
    described_class.new(
      admin_user_id: admin_user.id,
      child_support_id: child_support.id,
      call_session: call_session
    )
  end

  before do
    stub_request(:post, 'https://api.calendly.com/scheduling_links')
      .to_return(status: 201, body: success_response.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  describe '#initialize' do
    it 'initializes errors as an empty array' do
      expect(subject.errors).to eq([])
    end

    it 'initializes booking_url as nil' do
      expect(subject.booking_url).to be_nil
    end
  end

  describe '#call' do
    context 'when admin_user is not found' do
      subject do
        described_class.new(
          admin_user_id: 0,
          child_support_id: child_support.id,
          call_session: call_session
        )
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: "L'utilisateur n'a pas été trouvé"))
      end

      it 'does not make an API call' do
        subject.call
        expect(WebMock).not_to have_requested(:post, 'https://api.calendly.com/scheduling_links')
      end
    end

    context 'when child_support is not found' do
      subject do
        described_class.new(
          admin_user_id: admin_user.id,
          child_support_id: 0,
          call_session: call_session
        )
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: "La fiche de suivi n'a pas été trouvé"))
      end

      it 'does not make an API call' do
        subject.call
        expect(WebMock).not_to have_requested(:post, 'https://api.calendly.com/scheduling_links')
      end
    end

    context 'when event_type_uri is not found for call_session' do
      let(:calendly_event_type_uris) { { 'call0' => calendly_event_type_uri } }

      subject do
        described_class.new(
          admin_user_id: admin_user.id,
          child_support_id: child_support.id,
          call_session: 2
        )
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(
          message: "L'event type pour l'appel 2 n'a pas été trouvé",
          admin_user_id: admin_user.id,
          call_session: 2
        ))
      end

      it 'does not make an API call' do
        subject.call
        expect(WebMock).not_to have_requested(:post, 'https://api.calendly.com/scheduling_links')
      end
    end

    context 'when API call is successful' do
      it 'returns self with no errors' do
        result = subject.call
        expect(result.errors).to be_empty
      end

      it 'sets booking_url with UTM parameters' do
        result = subject.call
        expect(result.booking_url).to include(booking_url)
        expect(result.booking_url).to include('utm_source=1001mots')
        expect(result.booking_url).to include("utm_campaign=call#{call_session}")
        expect(result.booking_url).to include("utm_content=#{parent.security_token}")
      end

      it 'sends correct parameters to Calendly API' do
        subject.call
        expect(WebMock).to have_requested(:post, 'https://api.calendly.com/scheduling_links')
          .with(body: hash_including(
            'max_event_count' => '1',
            'owner' => calendly_event_type_uri,
            'owner_type' => 'EventType'
          ))
      end
    end

    context 'when API call fails' do
      before do
        stub_request(:post, 'https://api.calendly.com/scheduling_links')
          .to_return(
            status: 400,
            body: { 'details' => 'Invalid event type' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns an error with details' do
        result = subject.call
        expect(result.errors).to include(hash_including(
          message: 'La création du lien à usage unique a échoué',
          details: 'Invalid event type',
          child_support_id: child_support.id,
          admin_user_id: admin_user.id
        ))
      end

      it 'does not set booking_url' do
        result = subject.call
        expect(result.booking_url).to be_nil
      end
    end

    context 'when parent has no security_token' do
      before do
        parent.update!(security_token: nil)
      end

      it 'still generates a valid URL without utm_content' do
        result = subject.call
        expect(result.booking_url).to include('utm_source=1001mots')
        expect(result.booking_url).to include("utm_campaign=call#{call_session}")
        expect(result.booking_url).not_to include('utm_content')
      end
    end

    context 'with different call sessions' do
      [0, 1, 2, 3].each do |session|
        context "when call_session is #{session}" do
          let(:call_session) { session }

          it "includes utm_campaign=call#{session}" do
            result = subject.call
            expect(result.booking_url).to include("utm_campaign=call#{session}")
          end
        end
      end
    end
  end

  describe '#add_utm_params' do
    it 'properly encodes special characters in security_token' do
      result = subject.call
      uri = URI.parse(result.booking_url)
      params = URI.decode_www_form(uri.query).to_h

      expect(params['utm_source']).to eq('1001mots')
      expect(params['utm_campaign']).to eq("call#{call_session}")
      expect(params['utm_content']).to eq(parent.security_token)
    end
  end
end
