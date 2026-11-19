require 'rails_helper'

# Toute réponse d'erreur affiche la page commune de la charte (app/errors/error_page.rb),
# jamais une page blanche ni un texte brut.
RSpec.describe 'Pages d’erreur', type: :request do
  around do |example|
    env_config = Rails.application.env_config
    anciennes = env_config.values_at('action_dispatch.show_exceptions', 'action_dispatch.show_detailed_exceptions')
    env_config['action_dispatch.show_exceptions'] = true
    env_config['action_dispatch.show_detailed_exceptions'] = false
    example.run
  ensure
    env_config['action_dispatch.show_exceptions'], env_config['action_dispatch.show_detailed_exceptions'] = anciennes
  end

  def expect_page_d_erreur(status, titre)
    expect(response).to have_http_status(status)
    expect(response.media_type).to eq('text/html')
    expect(response.body).to include("<h1>#{titre}</h1>")
    expect(response.body).not_to include('{{')
  end

  it 'affiche la 404 pour une page inconnue' do
    get '/n-importe-quoi'

    expect_page_d_erreur(404, "Cette page n'existe pas ou n'existe plus")
  end

  it 'affiche la 404 (et non une page blanche) pour un lien parent inexistant' do
    get '/c/99999999/ab'

    expect_page_d_erreur(404, "Cette page n'existe pas ou n'existe plus")
  end

  it 'affiche la 404 pour un lien court inexistant' do
    get '/r/99999999/ab'

    expect_page_d_erreur(404, "Cette page n'existe pas ou n'existe plus")
  end

  it 'affiche la 404 pour un atelier dont le jeton parent est inconnu' do
    get '/w/jeton-inconnu/1'

    expect_page_d_erreur(404, "Cette page n'existe pas ou n'existe plus")
  end

  it 'affiche la page 400 pour des paramètres mal formés' do
    get '/inscription?a[b=1&c[]=%FF'

    expect_page_d_erreur(400, "La demande n'a pas pu aboutir")
  end

  it 'affiche la page commune pour un format inconnu (406)' do
    get '/inscription.xml'

    expect_page_d_erreur(406, 'Une erreur est survenue')
  end

  it 'affiche la page 500 pour une erreur serveur' do
    allow(Child).to receive(:where).and_raise(StandardError, 'panne')

    get '/c/1/ab'

    expect_page_d_erreur(500, 'Une erreur est survenue')
  end

  describe ErrorPage do
    it 'lit le code HTTP dans le chemin que Rails lui transmet' do
      status, headers, body = described_class.call('PATH_INFO' => '/422')

      expect(status).to eq(422)
      expect(headers['Content-Type']).to eq('text/html; charset=utf-8')
      expect(body.first).to include("<h1>La demande n'a pas pu aboutir</h1>")
    end

    it 'retombe sur 500 quand le chemin ne porte pas de code' do
      status, = described_class.call('PATH_INFO' => '/')

      expect(status).to eq(500)
    end

    it 'sert les 429 de Rack::Attack, avec leur en-tête Retry-After' do
      status, headers, body = described_class.response(429, 'Retry-After' => '60')

      expect(status).to eq(429)
      expect(headers['Retry-After']).to eq('60')
      expect(body.first).to include('<h1>Trop de tentatives</h1>')
    end
  end
end
