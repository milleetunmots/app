require 'rails_helper'

RSpec.describe 'Admin stop support form', type: :request do
  def stop_bundle(name, key)
    FactoryBot.create(:media_text_messages_bundle, name: name, body1: "Texte du trio #{name}", body2: nil, body3: nil).tap { |bundle| bundle.update_column(:key, key) }
  end

  def lea(contact_parent: true)
    group = FactoryBot.create(:group, started_at: Time.zone.today.prev_occurring(:monday) - 8.weeks)
    FactoryBot.create(:child, first_name: 'Léa', group: group, group_status: 'active', should_contact_parent1: contact_parent)
  end

  def stop(child, reason)
    sign_in FactoryBot.create(:admin_user, user_role: 'caller', name: 'Marie')
    post '/admin/stop_support_form/perform', params: { child_support_id: child.child_support_id, reason: reason, details: 'Détails factuels' }
  end

  it 'indique que le message de désistement est envoyé quand le trio du motif existe' do
    stop_bundle('Arrêt · Pas assez francophone', 'arret_barriere_langue')

    stop(lea, 'family_limited_french_for_support')

    expect(flash[:notice]).to eq('Accompagnement arrêté et message de désistement envoyé aux parents')
  end

  it "indique que le message n'est pas envoyé quand le trio du motif est introuvable" do
    allow(Rollbar).to receive(:error)

    stop(lea, 'family_limited_french_for_support')

    expect(flash[:notice]).to eq('Accompagnement arrêté, message non envoyé')
  end

  it "indique qu'aucun message n'est envoyé quand aucun parent n'est à contacter" do
    child = lea(contact_parent: false)

    stop(child, 'program')

    expect(child.reload.group_status).to eq('stopped')
    expect(flash[:notice]).to eq('Accompagnement arrêté, aucun parent à contacter : aucun message envoyé')
  end
end
