require 'rails_helper'

RSpec.describe 'EventsController#spot_hit_response', type: :request do
  it 'alerte Rollbar sans le numéro du parent quand le trio de la réponse est introuvable' do
    lucas = FactoryBot.create(:child, first_name: 'Lucas', group: FactoryBot.create(:group), group_status: 'active')
    lucas.child_support.update!(supporter: FactoryBot.create(:admin_user, user_role: 'caller', name: 'Marie', aircall_phone_number: '0189000001'))
    allow(Rollbar).to receive(:error)

    get '/spot_hit/response', params: { numero: lucas.parent1.phone_number, message: 'Bonjour', id: '42', date: Time.zone.now.to_i }

    expect(response).to have_http_status(:ok)
    expect(Rollbar).to have_received(:error).with(
      'Events::SendMessageToParentResponseService',
      errors: ['Trio introuvable : « Numéro qui ne reçoit pas de SMS » (clé numero_sans_sms), message non envoyé']
    )
  end
end
