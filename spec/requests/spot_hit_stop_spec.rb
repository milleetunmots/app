require 'rails_helper'

RSpec.describe 'EventsController#spot_hit_stop', type: :request do
  let(:path) { '/spot_hit/stop' }

  def stop_params(numero:)
    { numero: numero, id: 'sms-42', date: Time.zone.local(2026, 11, 18, 10).to_i }
  end

  it "crée un message STOP dans l'historique du parent et répond 200" do
    parent = FactoryBot.create(:parent, phone_number: '0612345678')

    get path, params: stop_params(numero: '0612345678')

    expect(response).to have_http_status(:ok)
    stop_message = Events::TextMessage.find_by(related: parent)
    expect(stop_message).to have_attributes(
      body: 'STOP',
      spot_hit_message_id: 'sms-42',
      spot_hit_status: 1,
      occurred_at: Time.zone.local(2026, 11, 18, 10),
      originated_by_app: false
    )
  end

  it "décoche le parent seul et arrête l'enfant actif" do
    travel_to Time.zone.local(2026, 11, 18, 10)
    parent = FactoryBot.create(:parent, phone_number: '0612345678')
    child = FactoryBot.create(:child, parent1: parent, group: FactoryBot.create(:group), group_status: 'active')

    get path, params: stop_params(numero: '0612345678')

    child.reload
    expect(child.should_contact_parent1).to be(false)
    expect(child.group_status).to eq('stopped')
    expect(child.group_end).to eq(Date.new(2026, 11, 18))
  end

  it "décoche le parent 2 sans arrêter l'enfant quand le parent 1 reste à contacter" do
    parent1 = FactoryBot.create(:parent, phone_number: '0611111111')
    parent2 = FactoryBot.create(:parent, phone_number: '0622222222')
    child = FactoryBot.create(
      :child,
      parent1: parent1, parent2: parent2, should_contact_parent2: true,
      group: FactoryBot.create(:group), group_status: 'active'
    )

    get path, params: stop_params(numero: '0622222222')

    child.reload
    expect(child.should_contact_parent2).to be(false)
    expect(child.should_contact_parent1).to be(true)
    expect(child.group_status).to eq('active')
  end

  it "ne touche pas un enfant sur liste d'attente ni un enfant désengagé" do
    parent = FactoryBot.create(:parent, phone_number: '0612345678')
    waiting_child = FactoryBot.create(:child, parent1: parent, group: nil, group_status: 'waiting')
    disengaged_child = FactoryBot.create(:child, parent1: parent, group: FactoryBot.create(:group), group_status: 'disengaged')

    get path, params: stop_params(numero: '0612345678')

    expect(waiting_child.reload).to have_attributes(should_contact_parent1: true, group_status: 'waiting')
    expect(disengaged_child.reload).to have_attributes(should_contact_parent1: true, group_status: 'disengaged')
  end

  it 'ne crée rien pour un numéro absent de la base et répond 200' do
    expect do
      get path, params: stop_params(numero: '0700000000')
    end.not_to change(Events::TextMessage, :count)

    expect(response).to have_http_status(:ok)
  end
end
