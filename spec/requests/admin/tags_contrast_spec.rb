require 'rails_helper'

RSpec.describe 'Lisibilité des tags dans l’admin', type: :request do
  it 'écrit chaque tag dans la couleur de texte qui contraste avec son fond' do
    sign_in FactoryBot.create(:admin_user, user_role: 'super_admin')
    child = FactoryBot.create(:child)
    child.update!(tag_list: %w[fonce clair])
    Tag.find_by(name: 'fonce').update!(color: '#000000')
    Tag.find_by(name: 'clair').update!(color: '#f0f0f0')

    get "/admin/children/#{child.id}"

    page = Capybara.string(response.body)
    expect(page).to have_css("a.tag_display[style='background-color: #000000; color: #{TagDecorator::LIGHT_TEXT}']", text: 'fonce')
    expect(page).to have_css("a.tag_display[style='background-color: #f0f0f0; color: #{TagDecorator::DARK_TEXT}']", text: 'clair')
  end
end
