require 'rails_helper'

# « Vous avez oublié votre mot de passe ? » : pages ouvertes sans être connecté
RSpec.describe 'Admin — mot de passe oublié', type: :request do
  it 'affiche le formulaire de demande de lien sans être connecté' do
    get '/admin/password/new'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('admin_user[email]')
  end

  it 'envoie le lien de réinitialisation à l’adresse demandée' do
    admin_user = FactoryBot.create(:admin_user)

    expect do
      post '/admin/password', params: { admin_user: { email: admin_user.email } }
    end.to change { ActionMailer::Base.deliveries.count }.by(1)

    expect(ActionMailer::Base.deliveries.last.to).to eq([admin_user.email])
  end

  # Le logo est en tête de la carte (cf. brand.sass) : le titre ne répète pas « 1001mots »
  def titre_de_la_carte
    Nokogiri::HTML(response.body).at_css('#login h2').text.squish
  end

  it 'titre la demande de lien sans répéter le nom du logo' do
    get '/admin/password/new'

    expect(titre_de_la_carte).not_to include('1001mots')
    expect(titre_de_la_carte).to eq(I18n.t('active_admin.devise.reset_password.title'))
  end

  it 'titre le choix du nouveau mot de passe sans répéter le nom du logo' do
    token = FactoryBot.create(:admin_user).send(:set_reset_password_token)

    get '/admin/password/edit', params: { reset_password_token: token }

    expect(titre_de_la_carte).not_to include('1001mots')
    expect(titre_de_la_carte).to eq(I18n.t('active_admin.devise.change_password.title'))
  end
end
