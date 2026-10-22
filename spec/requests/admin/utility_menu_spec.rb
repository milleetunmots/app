require 'rails_helper'

RSpec.describe 'Admin — menu de l’avatar et menu de gauche', type: :request do
  def parsed_body
    Nokogiri::HTML(response.body)
  end

  def menu_entries
    parsed_body.css('#utility_nav #current_user > ul > li:not(#user_header)')
  end

  def left_menu_labels
    parsed_body.css('#tabs > li > a').map { |link| link.text.strip }
  end

  %w[caller animator].each do |role|
    describe "pour un #{role}" do
      let(:admin_user) { FactoryBot.create(:admin_user, user_role: role, name: 'Awa Traoré') }

      before do
        sign_in admin_user
        get '/admin/dashboard'
      end

      it 'ouvre un menu déroulant au lieu de mener directement aux réglages' do
        avatar = parsed_body.at_css('#utility_nav #current_user > a')

        expect(avatar['href']).to eq('#')
        expect(avatar.text).to include('Awa Traoré')
      end

      it 'affiche en en-tête son nom et son e-mail' do
        header = parsed_body.at_css('#utility_nav #current_user > ul > li#user_header')

        expect(header.text).to include('Awa Traoré', admin_user.email)
        expect(header.at_css('a')).to be_nil
      end

      it 'propose trois entrées, dans cet ordre' do
        expect(menu_entries.map { |entry| entry.text.strip }).to eq(
          ['Paramètres des rdv', "Mes statistiques d'appel", 'Mes informations personnelles']
        )
        expect(menu_entries.map { |entry| entry.at_css('a')&.[]('href') }).to eq(
          ['/admin/reglages_de_rdv', nil, "/admin/admin_users/#{admin_user.id}"]
        )
      end

      it 'laisse l’entrée statistiques sans lien pour l’instant' do
        statistics = parsed_body.at_css('#utility_nav #current_user > ul > li#call_statistics')

        expect(statistics.at_css('a')).to be_nil
        expect(statistics.at_css('span').text.strip).to eq("Mes statistiques d'appel")
      end

      it 'retire « Utilisateur » du menu de gauche' do
        expect(left_menu_labels).not_to include('Utilisateur')
      end

      it 'conserve l’encart des paramètres de rendez-vous' do
        expect(response.body).to include('Paramètres des rendez-vous')
      end

      it 'garde l’accès direct à sa liste d’utilisateurs régi par les droits' do
        get '/admin/admin_users'

        expect(response).to have_http_status(:ok)
      end
    end
  end

  %w[super_admin contributor reader].each do |role|
    describe "pour un #{role}" do
      let(:admin_user) { FactoryBot.create(:admin_user, user_role: role) }

      before do
        sign_in admin_user
        get '/admin/dashboard'
      end

      it 'a un avatar qui mène directement à son profil, sans menu déroulant' do
        avatar = parsed_body.at_css('#utility_nav #current_user > a')

        expect(avatar['href']).to eq(admin_admin_user_path(admin_user))
        expect(parsed_body.css('#utility_nav #current_user ul li')).to be_empty
      end

      it 'peut ouvrir son profil' do
        get admin_admin_user_path(admin_user)

        expect(response).to have_http_status(:ok)
      end

      it 'ne voit ni les liens du déroulant des accompagnantes' do
        expect(response.body).not_to include('Mes informations personnelles')
      end
    end
  end

  describe 'le menu de gauche des rôles qui lisent les utilisateurs' do
    %w[super_admin contributor reader].each do |role|
      it "affiche « Utilisateur » pour un #{role}" do
        sign_in FactoryBot.create(:admin_user, user_role: role)

        get '/admin/dashboard'

        expect(left_menu_labels).to include('Utilisateur')
      end
    end
  end
end
