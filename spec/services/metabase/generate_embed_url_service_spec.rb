require 'rails_helper'

RSpec.describe Metabase::GenerateEmbedUrlService do
  let(:secret_key) { 'clef-de-test' }
  let(:arguments) do
    { site_url: 'https://metabase.example.org', secret_key: secret_key, dashboard_id: 112, params: { 'accompagnante_id' => 42 } }
  end

  def token_from(url)
    url[%r{/embed/dashboard/([^#]+)#}, 1]
  end

  def decoded_payload(url, key = secret_key)
    JWT.decode(token_from(url), key, true, algorithm: 'HS256').first
  end

  describe '#call' do
    context 'avec une configuration complète' do
      it 'retourne le service lui-même' do
        service = described_class.new(**arguments)

        expect(service.call).to be(service)
      end

      it 'ne remonte aucune erreur' do
        expect(described_class.new(**arguments).call.errors).to be_empty
      end

      it 'construit l’adresse de l’iframe du dashboard' do
        url = described_class.new(**arguments).call.url

        expect(url).to start_with('https://metabase.example.org/embed/dashboard/')
        expect(url).to end_with('#bordered=true&titled=true')
      end

      it 'tolère une adresse de site terminée par une barre oblique' do
        url = described_class.new(**arguments, site_url: 'https://metabase.example.org/').call.url

        expect(url).to start_with('https://metabase.example.org/embed/dashboard/')
      end

      it 'signe un jeton désignant le dashboard et portant les paramètres' do
        payload = decoded_payload(described_class.new(**arguments).call.url)

        expect(payload['resource']).to eq('dashboard' => 112)
        expect(payload['params']).to eq('accompagnante_id' => 42)
      end

      it 'accepte l’id du dashboard sous forme de texte, comme une variable d’environnement' do
        payload = decoded_payload(described_class.new(**arguments, dashboard_id: '112').call.url)

        expect(payload['resource']).to eq('dashboard' => 112)
      end

      it 'fait expirer le jeton 10 minutes après l’appel' do
        freeze_time do
          payload = decoded_payload(described_class.new(**arguments).call.url)

          expect(payload['exp']).to eq(10.minutes.from_now.to_i)
        end
      end

      it 'respecte une durée de validité fournie' do
        freeze_time do
          payload = decoded_payload(described_class.new(**arguments, expires_in: 2.minutes).call.url)

          expect(payload['exp']).to eq(2.minutes.from_now.to_i)
        end
      end

      it 'signe avec la clef fournie et pas avec une autre' do
        url = described_class.new(**arguments).call.url

        expect { decoded_payload(url, 'autre-clef') }.to raise_error(JWT::VerificationError)
      end

      it 'ne laisse pas la clef apparaître dans l’adresse' do
        expect(described_class.new(**arguments).call.url).not_to include(secret_key)
      end

      it 'produit un jeton rejeté une fois expiré' do
        url = described_class.new(**arguments).call.url

        travel_to(11.minutes.from_now) do
          expect { decoded_payload(url) }.to raise_error(JWT::ExpiredSignature)
        end
      end

      it 'accepte des paramètres vides' do
        payload = decoded_payload(described_class.new(**arguments, params: {}).call.url)

        expect(payload['params']).to eq({})
      end
    end

    context 'quand une valeur de configuration manque' do
      [
        [:site_url, nil],
        [:site_url, ''],
        [:secret_key, nil],
        [:secret_key, ''],
        [:dashboard_id, nil],
        [:dashboard_id, '']
      ].each do |attribute, value|
        it "ne génère rien pour #{attribute} valant #{value.inspect}" do
          service = described_class.new(**arguments, attribute => value).call

          expect(service.url).to be_nil
          expect(service.errors).to eq(
            [{ message: 'La configuration de Metabase est incomplète', context: { missing: [attribute] } }]
          )
        end
      end

      it 'liste toutes les valeurs manquantes' do
        service = described_class.new(**arguments, site_url: nil, secret_key: nil, dashboard_id: nil).call

        expect(service.errors.first[:context][:missing]).to contain_exactly(:site_url, :secret_key, :dashboard_id)
      end

      it 'ne met jamais la clef dans le contexte de l’erreur' do
        service = described_class.new(**arguments, site_url: nil).call

        expect(service.errors.to_s).not_to include(secret_key)
      end
    end

    context 'quand l’id du dashboard est invalide' do
      ['abc', '0', '-3', '11.5'].each do |invalid_id|
        it "refuse #{invalid_id.inspect}" do
          service = described_class.new(**arguments, dashboard_id: invalid_id).call

          expect(service.url).to be_nil
          expect(service.errors).to eq(
            [{ message: 'L’identifiant du dashboard Metabase est invalide', context: { dashboard_id: invalid_id } }]
          )
        end
      end
    end

    it 'n’effectue aucun appel réseau' do
      described_class.new(**arguments).call

      expect(WebMock).not_to have_requested(:any, /.*/)
    end
  end
end
