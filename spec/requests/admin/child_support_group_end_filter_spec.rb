require 'rails_helper'

RSpec.describe 'Admin suivis — filtre Date de fin de cohorte', type: :request do
  # Le filtre s'appuie sur le scope Ransack `with_child_in_group_ended_between`,
  # que le Ransack::Search ne sait pas résoudre : l'input date_range natif
  # d'ActiveAdmin retombait donc systématiquement sur une valeur vide, obligeant
  # à ressaisir les dates à chaque itération de recherche.
  let(:gteq_param) { 'with_child_in_group_ended_between_gteq_datetime' }
  let(:lteq_param) { 'with_child_in_group_ended_between_lteq_datetime' }

  let!(:group_in_range) { FactoryBot.create(:group, ended_at: Date.new(2025, 9, 15)) }
  let!(:group_out_of_range) { FactoryBot.create(:group, ended_at: Date.new(2025, 11, 15)) }

  # Prénoms volontairement improbables : la page d'index affiche aussi les
  # parents, dont la factory tire les noms via Faker. Chercher un prénom banal
  # rendrait ces exemples dépendants de la graine.
  let!(:matching_support) { create_support_with_child('Zalicempi', group_in_range) }
  let!(:other_support) { create_support_with_child('Zbobempi', group_out_of_range) }

  before { sign_in FactoryBot.create(:admin_user, user_role: 'contributor') }

  def create_support_with_child(first_name, group)
    FactoryBot.create(:child_support).tap do |child_support|
      FactoryBot.create(:child, first_name: first_name, child_support: child_support,
                                group: group, group_status: 'stopped')
    end
  end

  # Le scope par défaut de la ressource est `mine` (suivis du current_admin_user) :
  # on force `all` pour que les suivis créés par les factories soient visibles.
  def get_index(query = nil)
    params = { scope: 'all' }
    params[:q] = query if query
    get '/admin/child_supports', params: params
  end

  # ActiveAdmin rend `value` avant `name` : on isole la balise par son `name`
  # plutôt que de dépendre de l'ordre des attributs.
  def filter_input_value(param_name)
    tag = response.body[/<input[^>]*name="q\[#{param_name}\]"[^>]*>/]
    expect(tag).not_to be_nil, "champ q[#{param_name}] absent de la page"
    tag[/value="([^"]*)"/, 1]
  end

  it 'conserve les dates saisies dans les champs du filtre' do
    get_index(gteq_param => '2025-09-01', lteq_param => '2025-09-30')

    expect(response).to have_http_status(:ok)
    expect(filter_input_value(gteq_param)).to eq('2025-09-01')
    expect(filter_input_value(lteq_param)).to eq('2025-09-30')
  end

  it 'ne retourne que les suivis dont la cohorte se termine dans l’intervalle' do
    get_index(gteq_param => '2025-09-01', lteq_param => '2025-09-30')

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Zalicempi')
    expect(response.body).not_to include('Zbobempi')
  end

  it 'laisse les champs vides quand aucune recherche n’est soumise' do
    get_index

    expect(response).to have_http_status(:ok)
    expect(filter_input_value(gteq_param)).to eq('')
    expect(filter_input_value(lteq_param)).to eq('')
  end

  it 'laisse le champ vide quand la date soumise est invalide' do
    get_index(gteq_param => 'pas-une-date', lteq_param => '2025-09-30')

    expect(response).to have_http_status(:ok)
    expect(filter_input_value(gteq_param)).to eq('')
    expect(filter_input_value(lteq_param)).to eq('2025-09-30')
  end
end
