require 'rails_helper'

RSpec.describe "Admin children — filtre Email d'inscription", type: :request do
  let!(:pmi_source) { FactoryBot.create(:source, channel: 'pmi', department: 80) }
  let!(:other_source) { FactoryBot.create(:source, channel: 'bao') }

  let!(:matching_child) { FactoryBot.create(:child, first_name: 'Alice') }
  let!(:other_child) { FactoryBot.create(:child, first_name: 'Bob') }
  let!(:child_without_source) { FactoryBot.create(:child, first_name: 'Chloé') }

  before do
    ChildrenSource.create!(child: matching_child, source: pmi_source,
                           professional_email: 'sage.femme@pmi-somme.fr')
    ChildrenSource.create!(child: other_child, source: other_source,
                           professional_email: 'contact@autre-structure.fr')
    sign_in FactoryBot.create(:admin_user, user_role: 'contributor')
  end

  it "ne retourne que les enfants dont l'email d'inscription correspond" do
    get '/admin/children', params: { q: { registration_professional_email_contains: 'pmi-somme' } }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Alice')
    expect(response.body).not_to include('Bob')
    expect(response.body).not_to include('Chloé')
  end

  it 'conserve la valeur saisie dans le champ du filtre' do
    get '/admin/children', params: { q: { registration_professional_email_contains: 'pmi-somme' } }

    expect(response.body).to include('pmi-somme')
  end

  # Le formulaire ActiveAdmin soumet Source et Canal d'inscription AVANT l'email :
  # dans cet ordre, Ransack construisait sa condition sur l'alias children_sources_children
  # (absent du FROM) et la page renvoyait une 500.
  it "répond quand le filtre Canal d'inscription est soumis avant l'email" do
    get '/admin/children', params: { q: { source_channel_in: ['pmi'],
                                          registration_professional_email_contains: 'pmi-somme' } }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Alice')
    expect(response.body).not_to include('Bob')
  end

  it "répond quand le filtre Source d'inscription est soumis avant l'email" do
    get '/admin/children', params: { q: { source_id_in: [pmi_source.id.to_s],
                                          registration_professional_email_contains: 'pmi-somme' } }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Alice')
  end

  it "répond quand l'email est combiné à plusieurs autres filtres" do
    get '/admin/children', params: { q: { source_channel_in: ['pmi'],
                                          registration_professional_email_contains: 'pmi-somme',
                                          first_name_contains: 'Ali' } }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Alice')
  end

  it 'ignore le filtre quand il est vide' do
    get '/admin/children', params: { q: { registration_professional_email_contains: '' } }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Alice')
    expect(response.body).to include('Bob')
    expect(response.body).to include('Chloé')
  end
end
