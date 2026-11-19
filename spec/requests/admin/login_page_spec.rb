require 'rails_helper'

# Page de connexion : le logo de 1001mots est en tête de la carte (cf. brand.sass), le
# titre se limite donc à « Connexion » au lieu de « 1001mots Connexion »
RSpec.describe 'Admin — page de connexion', type: :request do
  it 'titre la carte « Connexion », sans répéter le nom du logo' do
    get '/admin/login'

    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).at_css('#login h2').text.squish).to eq('Connexion')
  end
end
