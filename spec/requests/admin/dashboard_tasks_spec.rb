require 'rails_helper'

RSpec.describe 'Tâches du tableau de bord', type: :request do
  let!(:awa) { FactoryBot.create(:admin_user, user_role: 'caller', name: 'Awa') }
  let!(:treating_user) { FactoryBot.create(:admin_user, user_role: 'contributor', name: 'Binta') }

  let!(:pending_task) { FactoryBot.create(:task, title: 'Tâche pas commencée', reporter: awa) }
  let!(:in_progress_task) { FactoryBot.create(:task, title: 'Tâche en traitement', reporter: awa, status: 'in_progress', treated_by: treating_user) }
  let!(:done_task) { FactoryBot.create(:task, title: 'Tâche résolue', reporter: awa, done_at: Date.new(2026, 10, 12)) }
  let!(:discarded_task) { FactoryBot.create(:task, title: 'Tâche à la corbeille', reporter: awa, discarded_at: Time.zone.now) }
  let!(:other_task) { FactoryBot.create(:task, title: "Tâche d'une autre", reporter: treating_user) }

  def section(title)
    Nokogiri::HTML(response.body).css('.aat-section-title').find { |heading| heading.text.start_with?(title) }
  end

  def tasks_of(title)
    section(title).next_element.css('.aat-title').map { |node| node.text.strip }
  end

  before do
    sign_in awa
    get '/admin/dashboard'
  end

  it "sépare les tâches ajoutées par l'accompagnante en cours et résolues" do
    expect(response).to have_http_status(:ok)
    expect(section('En cours').text).to eq('En cours (2)')
    expect(tasks_of('En cours')).to contain_exactly('Tâche pas commencée', 'Tâche en traitement')
    expect(section('Résolues').text).to eq('Résolues (1)')
    expect(tasks_of('Résolues')).to eq(['Tâche résolue'])
  end

  it 'affiche où en est chaque tâche' do
    expect(response.body).to include('En cours de traitement par')
    expect(response.body).to include('Binta')
    expect(response.body).to include('Résolue le 12/10/2026')
    expect(response.body).to include('fa-check-circle')
  end

  it "n'affiche ni les tâches à la corbeille, ni celles des autres" do
    expect(response.body).not_to include('Tâche à la corbeille')
    expect(response.body).not_to include("Tâche d&#39;une autre")
  end

  it 'limite le suivi à 10 tâches, 7 en cours et 3 résolues, en gardant le total et le lien vers toutes' do
    FactoryBot.create_list(:task, 10, title: 'Autre en cours', reporter: awa)
    FactoryBot.create_list(:task, 6, title: 'Autre résolue', reporter: awa, done_at: Time.zone.today)

    get '/admin/dashboard'

    expect(section('En cours').text).to eq('En cours (12)')
    expect(tasks_of('En cours').size).to eq(7)
    expect(section('Résolues').text).to eq('Résolues (7)')
    expect(tasks_of('Résolues').size).to eq(3)
    expect(response.body).to include('Voir toutes mes tâches')
  end

  it "limite à 10 tâches les onglets d'un super_admin, avec un lien vers toutes" do
    super_admin = FactoryBot.create(:admin_user, user_role: 'super_admin')
    FactoryBot.create_list(:task, 11, title: 'À moi', assignee: super_admin)
    FactoryBot.create_list(:task, 11, title: 'À une autre', assignee: treating_user)
    sign_in super_admin

    get '/admin/dashboard'

    panel = Nokogiri::HTML(response.body).at_css('#active_admin-tasks-dashboard')
    titles = panel.css('.aat-title').map { |node| node.text.strip }
    expect(titles.count('À moi')).to eq(10)
    expect(titles.count('À une autre')).to eq(10)
    expect(panel.css('a[href*="scope=mine"]')).not_to be_empty
    expect(panel.css('a[href*="scope=all"]')).not_to be_empty
  end

  it "place le suivi en premier onglet pour l'accompagnante" do
    labels = Nokogiri::HTML(response.body).css('#active_admin-tasks-dashboard .nav-tabs a, #active_admin-tasks-dashboard .tabs ul a').map { |node| node.text.strip }

    expect(labels.first).to eq('Ajoutées par moi')
  end
end
