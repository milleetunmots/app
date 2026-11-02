require 'rails_helper'

RSpec.describe 'Logo de la nouvelle charte graphique', type: :request do
  it "affiche le nouveau logo dans le bandeau de l'admin" do
    sign_in FactoryBot.create(:admin_user, user_role: 'contributor')

    get '/admin/dashboard'

    logo = Nokogiri::HTML(response.body).at_css('#site_title_image')
    expect(logo['src']).to include('logo-1001mots')
  end

  # Les pages publiques restent sur l'ancienne charte (hors périmètre)
  it "garde l'ancien logo sur le formulaire d'inscription public" do
    get '/inscription'

    expect(Nokogiri::HTML(response.body).at_css('#mots-logo')['src']).to include('mots-logo')
  end
end
