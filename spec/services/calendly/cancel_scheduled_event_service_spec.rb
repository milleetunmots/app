require 'rails_helper'

RSpec.describe Calendly::CancelScheduledEventService do
  let(:event_uuid) { 'event123' }
  let(:event_uri) { "https://api.calendly.com/scheduled_events/#{event_uuid}" }
  let(:cancellation_url) do
    "#{Calendly::ApiBase::BASE_URL}#{Calendly::ApiBase::CANCELLATION_ENDPOINT.gsub('{uuid}', event_uuid)}"
  end
  let(:reason) { 'Remplacé par un nouveau RDV' }

  subject { described_class.new(event_uri: event_uri, reason: reason) }

  describe '#call' do
    context 'when the API call is successful' do
      before do
        stub_request(:post, cancellation_url)
          .to_return(status: 201, body: { 'resource' => { 'reason' => reason } }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns self with no errors' do
        result = subject.call
        expect(result.errors).to be_empty
      end

      it 'posts the cancellation with the reason' do
        subject.call
        expect(WebMock).to have_requested(:post, cancellation_url)
          .with(body: { 'reason' => reason })
      end
    end

    context 'when no reason is provided' do
      subject { described_class.new(event_uri: event_uri) }

      before do
        stub_request(:post, cancellation_url)
          .to_return(status: 201, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'posts an empty body' do
        subject.call
        expect(WebMock).to have_requested(:post, cancellation_url)
          .with(body: {})
      end
    end

    context 'when event_uri has a trailing slash' do
      subject { described_class.new(event_uri: "#{event_uri}/", reason: reason) }

      before do
        stub_request(:post, cancellation_url)
          .to_return(status: 201, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'still extracts the uuid and posts to the cancellation endpoint' do
        result = subject.call
        expect(WebMock).to have_requested(:post, cancellation_url)
        expect(result.errors).to be_empty
      end
    end

    context 'when the reason exceeds the API limit' do
      subject { described_class.new(event_uri: event_uri, reason: 'a' * 10_001) }

      before do
        stub_request(:post, cancellation_url)
          .to_return(status: 201, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'truncates the reason to 10000 characters' do
        subject.call
        expect(WebMock).to have_requested(:post, cancellation_url)
          .with { |req| JSON.parse(req.body)['reason'].length == described_class::MAX_REASON_LENGTH }
      end
    end

    context 'when the API call fails' do
      before do
        stub_request(:post, cancellation_url)
          .to_return(status: 403, body: { 'message' => 'Forbidden' }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns an error with the details and the event_uri' do
        result = subject.call
        expect(result.errors).to include(hash_including(
          message: "L'annulation de l'événement Calendly a échoué",
          details: 'Forbidden',
          event_uri: event_uri
        ))
      end
    end

    context 'when event_uri is blank' do
      subject { described_class.new(event_uri: nil) }

      it 'returns an error without making an API call' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: "L'URI de l'événement calendly est requis"))
        expect(WebMock).not_to have_requested(:post, /calendly/)
      end
    end
  end
end
