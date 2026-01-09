require 'rails_helper'

RSpec.describe Calendly::FetchScheduledEventService do
  let(:event_uri) { 'https://api.calendly.com/scheduled_events/event123' }

  let(:success_response) do
    {
      'resource' => {
        'uri' => event_uri,
        'name' => 'Appel 0 - Test',
        'start_time' => '2026-01-15T10:00:00Z',
        'end_time' => '2026-01-15T10:30:00Z',
        'event_type' => 'https://api.calendly.com/event_types/abc123',
        'status' => 'active',
        'location' => {
          'type' => 'inbound_call',
          'location' => '+33123456789'
        },
        'created_at' => '2026-01-10T09:00:00Z',
        'updated_at' => '2026-01-10T09:00:00Z'
      }
    }
  end

  subject { described_class.new(event_uri: event_uri) }

  before do
    stub_request(:get, event_uri)
      .to_return(status: 200, body: success_response.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  describe '#initialize' do
    it 'initializes errors as an empty array' do
      expect(subject.errors).to eq([])
    end

    it 'initializes event_data as nil' do
      expect(subject.event_data).to be_nil
    end
  end

  describe '#call' do
    context 'when event_uri is nil' do
      subject { described_class.new(event_uri: nil) }

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: "L'URI de l'événement est requis"))
      end

      it 'does not make an API call' do
        subject.call
        expect(WebMock).not_to have_requested(:get, event_uri)
      end
    end

    context 'when event_uri is blank' do
      subject { described_class.new(event_uri: '') }

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: "L'URI de l'événement est requis"))
      end
    end

    context 'when API call is successful' do
      it 'returns self with no errors' do
        result = subject.call
        expect(result.errors).to be_empty
      end

      it 'sets event_data with parsed response' do
        result = subject.call
        expect(result.event_data).not_to be_nil
      end

      it 'parses start_time correctly' do
        result = subject.call
        expect(result.event_data[:start_time]).to eq(Time.zone.parse('2026-01-15T10:00:00Z'))
      end

      it 'parses end_time correctly' do
        result = subject.call
        expect(result.event_data[:end_time]).to eq(Time.zone.parse('2026-01-15T10:30:00Z'))
      end

      it 'calculates duration_minutes correctly' do
        result = subject.call
        expect(result.event_data[:duration_minutes]).to eq(30)
      end

      it 'extracts event_type_uri' do
        result = subject.call
        expect(result.event_data[:event_type_uri]).to eq('https://api.calendly.com/event_types/abc123')
      end

      it 'extracts event_type_name' do
        result = subject.call
        expect(result.event_data[:event_type_name]).to eq('Appel 0 - Test')
      end

      it 'extracts status' do
        result = subject.call
        expect(result.event_data[:status]).to eq('active')
      end

      it 'extracts location (phone number)' do
        result = subject.call
        expect(result.event_data[:location]).to eq('+33123456789')
      end
    end

    context 'when API returns an error' do
      before do
        stub_request(:get, event_uri)
          .to_return(status: 404, body: { 'title' => 'Resource Not Found', 'message' => 'Event not found' }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns an error with details' do
        result = subject.call
        expect(result.errors).to include(hash_including(
          message: "Échec de la récupération de l'événement",
          event_uri: event_uri
        ))
      end

      it 'does not set event_data' do
        result = subject.call
        expect(result.event_data).to be_nil
      end
    end

    context 'when API returns 401 Unauthorized' do
      before do
        stub_request(:get, event_uri)
          .to_return(status: 401, body: { 'title' => 'Unauthorized', 'message' => 'Invalid API token' }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: "Échec de la récupération de l'événement"))
      end
    end

    context 'with different event durations' do
      [
        { start: '2026-01-15T10:00:00Z', end: '2026-01-15T10:15:00Z', expected: 15 },
        { start: '2026-01-15T10:00:00Z', end: '2026-01-15T11:00:00Z', expected: 60 },
        { start: '2026-01-15T10:00:00Z', end: '2026-01-15T10:45:00Z', expected: 45 }
      ].each do |test_case|
        context "when event is #{test_case[:expected]} minutes long" do
          before do
            success_response['resource']['start_time'] = test_case[:start]
            success_response['resource']['end_time'] = test_case[:end]
            stub_request(:get, event_uri)
              .to_return(status: 200, body: success_response.to_json, headers: { 'Content-Type' => 'application/json' })
          end

          it "calculates duration as #{test_case[:expected]} minutes" do
            result = subject.call
            expect(result.event_data[:duration_minutes]).to eq(test_case[:expected])
          end
        end
      end
    end
  end
end
