require 'rails_helper'

RSpec.describe JsonResponseConcern do
  let(:dummy_class) do
    Class.new do
      include JsonResponseConcern

      def get(url)
        HTTP.get(url)
      end
    end
  end
  let(:service) { dummy_class.new }
  let(:url) { 'https://api.example.com/resource' }
  let(:response) { service.get(url) }

  def stub_api(status:, body:, content_type: 'application/json')
    stub_request(:get, url).to_return(status: status, body: body, headers: { 'Content-Type' => content_type })
  end

  describe '#parse_json_response' do
    context 'when the response is a 2xx with valid JSON' do
      before { stub_api(status: 200, body: { 'id' => 42 }.to_json) }

      it 'returns the parsed body' do
        expect(service.parse_json_response(response)).to eq({ 'id' => 42 })
      end
    end

    context 'when the response is a 2xx with a non-JSON body' do
      # le cas Rollbar #983 : Spot-Hit répond "error" en texte brut avec un 200
      before { stub_api(status: 200, body: 'error', content_type: 'text/html') }

      it 'returns nil instead of raising JSON::ParserError' do
        expect { service.parse_json_response(response) }.not_to raise_error
        expect(service.parse_json_response(response)).to be_nil
      end
    end

    context 'when the response is a 502 with an HTML error page' do
      before { stub_api(status: 502, body: '<html><body>Bad Gateway</body></html>', content_type: 'text/html') }

      it 'returns nil' do
        expect(service.parse_json_response(response)).to be_nil
      end
    end

    context 'when the response is a 4xx with a valid JSON error body' do
      before { stub_api(status: 403, body: { 'message' => 'Forbidden' }.to_json) }

      it 'returns nil because the status is not a success' do
        expect(service.parse_json_response(response)).to be_nil
      end
    end
  end

  describe '#parse_json_body' do
    context 'when the response is a 4xx with a valid JSON error body' do
      before { stub_api(status: 403, body: { 'message' => 'Forbidden' }.to_json) }

      it 'returns the parsed body despite the status' do
        expect(service.parse_json_body(response)).to eq({ 'message' => 'Forbidden' })
      end
    end

    context 'when the body is not valid JSON' do
      before { stub_api(status: 503, body: 'Service Unavailable', content_type: 'text/plain') }

      it 'returns nil instead of raising' do
        expect { service.parse_json_body(response) }.not_to raise_error
        expect(service.parse_json_body(response)).to be_nil
      end
    end
  end

  describe '#parse_json_resource' do
    context 'when the resource is present' do
      before { stub_api(status: 200, body: { 'contact' => { 'id' => 7 } }.to_json) }

      it 'returns the nested resource' do
        expect(service.parse_json_resource(response, 'contact')).to eq({ 'id' => 7 })
      end
    end

    context 'when the body is an array' do
      before { stub_api(status: 200, body: [1, 2].to_json) }

      it 'returns nil instead of raising' do
        expect { service.parse_json_resource(response, 'contact') }.not_to raise_error
        expect(service.parse_json_resource(response, 'contact')).to be_nil
      end
    end

    context 'when the response is unusable' do
      before { stub_api(status: 500, body: 'boom', content_type: 'text/plain') }

      it 'returns nil' do
        expect(service.parse_json_resource(response, 'contact')).to be_nil
      end
    end
  end

  describe '#json_error_message' do
    context 'when the body carries a nested error message' do
      before { stub_api(status: 400, body: { 'error' => { 'message' => 'Invalid template' } }.to_json) }

      it 'includes the status and the API detail' do
        body = service.parse_json_body(response)
        expect(service.json_error_message(response, body)).to include('400', 'Invalid template')
      end
    end

    context 'when the body is not exploitable' do
      before { stub_api(status: 502, body: 'error', content_type: 'text/html') }

      it 'falls back on the raw body' do
        expect(service.json_error_message(response, nil)).to include('502', 'error')
      end
    end

    # Les appelants qui gatent le succès sur parse_json_response n'ont pas de
    # corps parsé à passer sur un 4xx : on doit quand même exploiter le JSON
    # d'erreur de l'API plutôt que recracher le corps brut.
    context 'when no body is passed but the response carries a JSON error' do
      before { stub_api(status: 400, body: { 'error' => { 'message' => 'Invalid template' } }.to_json) }

      it 'parses the body itself to extract the detail' do
        expect(service.json_error_message(response)).to eq('HTTP 400 Bad Request — Invalid template')
      end
    end
  end
end
