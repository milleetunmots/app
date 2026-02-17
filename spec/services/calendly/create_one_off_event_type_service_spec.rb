require 'rails_helper'

RSpec.describe Calendly::CreateOneOffEventTypeService do
  let(:calendly_user_uri) { 'https://api.calendly.com/users/abc123' }
  let(:aircall_phone_number) { '+33123456789' }
  let(:supporter) do
    FactoryBot.create(:admin_user,
      calendly_user_uri: calendly_user_uri,
      aircall_phone_number: aircall_phone_number
    )
  end
  let(:parent) { FactoryBot.create(:parent) }
  let(:group) { FactoryBot.create(:group, started_at: Date.current.beginning_of_week(:monday)) }
  let(:child) { FactoryBot.create(:child, parent1: parent, group: group, group_status: 'active') }
  let(:child_support) { child.child_support.tap { |cs| cs.update!(supporter: supporter) } }
  let(:call_session) { 0 }

  let(:booking_url) { 'https://calendly.com/d/one-off-xyz789' }
  let(:success_response) do
    {
      'resource' => {
        'booking_url' => booking_url,
        'uri' => 'https://api.calendly.com/one_off_event_types/xyz789'
      }
    }
  end

  subject do
    described_class.new(
      child_support: child_support,
      call_session: call_session
    )
  end

  before do
    stub_request(:post, 'https://api.calendly.com/one_off_event_types')
      .to_return(status: 201, body: success_response.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  describe '#initialize' do
    it 'initializes errors as an empty array' do
      expect(subject.errors).to eq([])
    end
  end

  describe '#call' do
    context 'when child_support is nil' do
      subject do
        described_class.new(
          child_support: nil,
          call_session: call_session
        )
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include("La fiche de suivi n'a pas été trouvée")
      end

      it 'does not make an API call' do
        subject.call
        expect(WebMock).not_to have_requested(:post, 'https://api.calendly.com/one_off_event_types')
      end
    end

    context 'when supporter is not found' do
      before do
        child_support.update!(supporter: nil)
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include("Pas d'accompagnante sur la fiche de suivi")
      end

      it 'does not make an API call' do
        subject.call
        expect(WebMock).not_to have_requested(:post, 'https://api.calendly.com/one_off_event_types')
      end
    end

    context 'when supporter has no calendly_user_uri' do
      before do
        supporter.update!(calendly_user_uri: nil)
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include("L'accompagnante n'a pas de calendly_user_uri")
      end

      it 'does not make an API call' do
        subject.call
        expect(WebMock).not_to have_requested(:post, 'https://api.calendly.com/one_off_event_types')
      end
    end

    context 'when supporter has no aircall_phone_number' do
      before do
        supporter.update!(aircall_phone_number: nil)
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include("L'accompagnante n'a pas de numéro Aircall")
      end

      it 'does not make an API call' do
        subject.call
        expect(WebMock).not_to have_requested(:post, 'https://api.calendly.com/one_off_event_types')
      end
    end

    context 'when group is not found' do
      let(:child_without_group) { FactoryBot.create(:child, parent1: parent, group: nil, group_status: 'waiting') }
      let(:child_support_without_group) { child_without_group.child_support.tap { |cs| cs.update!(supporter: supporter) } }

      subject do
        described_class.new(
          child_support: child_support_without_group,
          call_session: call_session
        )
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include("Cohorte introuvable")
      end

      it 'does not make an API call' do
        subject.call
        expect(WebMock).not_to have_requested(:post, 'https://api.calendly.com/one_off_event_types')
      end
    end

    context 'when call dates are not defined' do
      before do
        group.update_columns(call0_start_date: nil, call0_end_date: nil)
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include("Les dates de la session d'appel de la cohorte sont manquantes")
      end

      it 'does not make an API call' do
        subject.call
        expect(WebMock).not_to have_requested(:post, 'https://api.calendly.com/one_off_event_types')
      end
    end

    context 'when API call is successful' do
      it 'returns self with no errors' do
        result = subject.call
        expect(result.errors).to be_empty
      end

      it 'saves booking_url to parent with UTM parameters' do
        subject.call
        parent.reload
        saved_url = parent.calendly_booking_urls["call#{call_session}"]
        expect(saved_url).to include(booking_url)
        expect(saved_url).to include('utm_source=1001mots')
        expect(saved_url).to include("utm_campaign=call#{call_session}")
        expect(saved_url).to include("utm_content=#{parent.security_token}")
      end

      it 'sends correct parameters to Calendly API' do
        subject.call
        expect(WebMock).to have_requested(:post, 'https://api.calendly.com/one_off_event_types')
          .with(body: hash_including(
            'name' => "Prenons 20 minutes pour discuter de #{child.first_name} :)",
            'host' => calendly_user_uri,
            'duration' => 40,
            'date_setting' => {
              'type' => 'date_range',
              'start_date' => group.call0_start_date.to_s,
              'end_date' => group.call0_end_date.to_s
            },
            'location' => {
              'kind' => 'inbound_call',
              'phone_number' => aircall_phone_number,
              'additional_info' => "Je vous appellerai sur votre numéro (j'aurai peut-être quelques minutes d'avance ou de retard)"
            },
            'locale' => 'fr'
          ))
      end
    end

    context 'when API call fails' do
      before do
        stub_request(:post, 'https://api.calendly.com/one_off_event_types')
          .to_return(
            status: 400,
            body: { 'message' => 'Invalid request', 'details' => 'Host not found' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns an error with details' do
        result = subject.call
        expect(result.errors).to include(hash_including(
          message: "La création d'un event type one-off a échoué",
          child_support_id: child_support.id,
          supporter_id: supporter.id,
          call_session: call_session
        ))
      end

      it 'does not set booking_url' do
        subject.call
        parent.reload
        expect(parent.calendly_booking_urls["call#{call_session}"]).to be_nil
      end
    end

    context 'when response contains scheduling_url instead of booking_url' do
      let(:success_response) do
        {
          'resource' => {
            'scheduling_url' => booking_url,
            'uri' => 'https://api.calendly.com/one_off_event_types/xyz789'
          }
        }
      end

      it 'extracts the URL correctly' do
        subject.call
        parent.reload
        expect(parent.calendly_booking_urls["call#{call_session}"]).to include(booking_url)
      end
    end

    context 'when parent has no security_token' do
      before do
        parent.update!(security_token: nil)
      end

      it 'still generates a valid URL without utm_content' do
        subject.call
        parent.reload
        expect(parent.calendly_booking_urls["call#{call_session}"]).to include('utm_source=1001mots')
        expect(parent.calendly_booking_urls["call#{call_session}"]).to include("utm_campaign=call#{call_session}")
        expect(parent.calendly_booking_urls["call#{call_session}"]).not_to include('utm_content')
      end
    end

    context 'with different call sessions' do
      (0..3).each do |session|
        context "when call_session is #{session}" do
          let(:call_session) { session }

          it "uses correct date range for call#{session}" do
            subject.call
            expected_start = group.send("call#{session}_start_date").to_s
            expected_end = group.send("call#{session}_end_date").to_s

            expect(WebMock).to have_requested(:post, 'https://api.calendly.com/one_off_event_types')
              .with(body: hash_including(
                'date_setting' => {
                  'type' => 'date_range',
                  'start_date' => expected_start,
                  'end_date' => expected_end
                }
              ))
          end

          it "includes utm_campaign=call#{session}" do
            subject.call
            parent.reload
            expect(parent.calendly_booking_urls["call#{session}"]).to include("utm_campaign=call#{session}")
          end
        end
      end
    end

  end

  describe '#add_utm_params' do
    it 'properly encodes special characters in security_token' do
      subject.call
      parent.reload
      uri = URI.parse(parent.calendly_booking_urls["call#{call_session}"])
      params = URI.decode_www_form(uri.query).to_h

      expect(params['utm_source']).to eq('1001mots')
      expect(params['utm_campaign']).to eq("call#{call_session}")
      expect(params['utm_content']).to eq(parent.security_token)
    end
  end
end
