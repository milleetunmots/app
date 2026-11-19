require 'rails_helper'

# La mention « Propulsé par Active Admin » est retirée partout (décision du produit,
# 2026-11-17). config.footer vide ne suffit pas : le composant Footer d'ActiveAdmin
# affiche alors active_admin.powered_by, d'où la surcharge de la traduction.
RSpec.describe 'Admin — pied de page', type: :request do
  def texte_de_la_page
    Nokogiri::HTML(response.body).at_css('body').text
  end

  it 'n’affiche aucune mention d’Active Admin dans les pages connectées' do
    sign_in FactoryBot.create(:admin_user, user_role: 'super_admin')

    get '/admin/tasks'

    expect(response).to have_http_status(:ok)
    expect(texte_de_la_page).not_to match(/Propulsé|Active\s?Admin/i)
  end

  it 'n’affiche aucune mention d’Active Admin sur la page de connexion' do
    get '/admin/login'

    expect(response).to have_http_status(:ok)
    expect(texte_de_la_page).not_to match(/Propulsé|Active\s?Admin/i)
  end
end
