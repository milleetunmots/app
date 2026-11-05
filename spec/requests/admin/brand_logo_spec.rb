require 'rails_helper'

RSpec.describe 'Logo de la nouvelle charte graphique', type: :request do
  it "affiche le nouveau logo dans le bandeau de l'admin" do
    sign_in FactoryBot.create(:admin_user, user_role: 'contributor')

    get '/admin/dashboard'

    logo = Nokogiri::HTML(response.body).at_css('#site_title_image')
    expect(logo['src']).to include('logo-1001mots')
  end

  # Logo entier hors développement (staging et prod tournent en production),
  # tuile « 0 » en local pour reconnaître ses onglets (config.x.favicon)
  describe 'favicon' do
    def favicon_declare
      Nokogiri::HTML(response.body).at_css('link[rel~="icon"]')['href']
    end

    it 'déclare le favicon du logo entier dans les pages de l’admin' do
      sign_in FactoryBot.create(:admin_user, user_role: 'contributor')

      get '/admin/dashboard'

      expect(favicon_declare).to match(%r{/favicon-\h+\.ico\z})
    end

    it 'déclare le favicon du logo entier dans les pages publiques' do
      get '/inscription'

      expect(favicon_declare).to match(%r{/favicon-\h+\.ico\z})
    end

    it 'réserve la tuile « 0 » au développement' do
      expect(Rails.application.config.x.favicon).to eq('favicon.ico')
      expect(Rails.root.join('config/environments/development.rb').read).to include("config.x.favicon = 'favicon-dev.ico'")
    end

    %w[favicon.ico favicon-dev.ico].each do |fichier|
      it "fournit #{fichier} en 16, 32 et 48 px" do
        ico = Rails.root.join('app/assets/images', fichier).binread

        # en-tête ICO : réservé, type 1 (icône), nombre d'images
        expect(ico.unpack('vvv')).to eq([0, 1, 3])
        expect(Array.new(3) { |i| ico.getbyte(6 + (16 * i)) }).to eq([16, 32, 48])
      end
    end

    it 'distingue bien les deux favicons' do
      expect(Rails.root.join('app/assets/images/favicon.ico').binread)
        .not_to eq(Rails.root.join('app/assets/images/favicon-dev.ico').binread)
    end
  end

  # /favicon.ico est demandé directement par les navigateurs (URL tapée, pages sans <link>)
  it 'sert le même favicon à la racine du site' do
    expect(Rails.public_path.join('favicon.ico').binread).to eq(Rails.root.join('app/assets/images/favicon.ico').binread)
  end

  # Les pages publiques restent sur l'ancienne charte (hors périmètre)
  it "garde l'ancien logo sur le formulaire d'inscription public" do
    get '/inscription'

    expect(Nokogiri::HTML(response.body).at_css('#mots-logo')['src']).to include('mots-logo')
  end
end
