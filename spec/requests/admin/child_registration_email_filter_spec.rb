require 'rails_helper'

RSpec.describe "Admin children — filtre Email d'inscription", type: :request do
  # Prénoms volontairement improbables : la page d'index affiche aussi les
  # parents, dont la factory tire les noms via Faker. Chercher « Bob » dans
  # tout le HTML rendait ces exemples dépendants de la graine.
  let!(:pmi_source) { FactoryBot.create(:source, channel: 'pmi', department: 80) }
  let!(:other_source) { FactoryBot.create(:source, channel: 'bao') }

  let!(:matching_child) { FactoryBot.create(:child, first_name: 'Zalicempi') }
  let!(:other_child) { FactoryBot.create(:child, first_name: 'Zbobempi') }
  let!(:child_without_source) { FactoryBot.create(:child, first_name: 'Zchloempi') }

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
    expect(response.body).to include('Zalicempi')
    expect(response.body).not_to include('Zbobempi')
    expect(response.body).not_to include('Zchloempi')
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
    expect(response.body).to include('Zalicempi')
    expect(response.body).not_to include('Zbobempi')
  end

  it "répond quand le filtre Source d'inscription est soumis avant l'email" do
    get '/admin/children', params: { q: { source_id_in: [pmi_source.id.to_s],
                                          registration_professional_email_contains: 'pmi-somme' } }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Zalicempi')
  end

  it "répond quand l'email est combiné à plusieurs autres filtres" do
    get '/admin/children', params: { q: { source_channel_in: ['pmi'],
                                          registration_professional_email_contains: 'pmi-somme',
                                          first_name_contains: 'Zalice' } }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Zalicempi')
  end

  it 'ignore le filtre quand il est vide' do
    get '/admin/children', params: { q: { registration_professional_email_contains: '' } }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Zalicempi')
    expect(response.body).to include('Zbobempi')
    expect(response.body).to include('Zchloempi')
  end
end
