require 'rails_helper'

RSpec.describe 'Date du dernier envoi d’un lien de RDV par le formulaire Message', type: :request do
  let!(:supporter) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let!(:parent) { FactoryBot.create(:parent) }
  let(:session_start) { Date.current.next_occurring(:monday) + 1.week }
  let!(:group) { FactoryBot.create(:group, started_at: session_start) }
  let!(:child) do
    FactoryBot.create(:child, parent1: parent, should_contact_parent1: true, group: group, group_status: 'active')
  end

  before do
    child.child_support.update!(supporter: supporter)
    sign_in supporter
  end

  def send_reminder
    post '/admin/message/program_sms',
         params: {
           planned_date: Time.zone.today.to_s,
           planned_hour: Time.zone.now.strftime('%H:%M'),
           recipients: ["parent.#{parent.id}"],
           group_status: ['active'],
           parent_id: parent.id,
           call_goals_sms: 'scheduled_call_reminder',
           message: 'Prenez RDV ici : https://calendly.com/d/lien'
         },
         headers: { 'HTTP_REFERER' => '/admin/tasks' }
  end

  it 'rattache l’envoi à la session en cours' do
    travel_to(session_start + 3.days) { send_reminder }

    expect(parent.reload.calendly_last_booking_dates).to eq('call0' => (session_start + 3.days).to_s)
  end

  # « Relancer » est proposé dès 2 jours avant le début de la session
  it 'rattache l’envoi à la session qui commence dans les 2 jours' do
    travel_to(session_start - 2.days) { send_reminder }

    expect(parent.reload.calendly_last_booking_dates).to eq('call0' => (session_start - 2.days).to_s)
  end

  it 'n’enregistre rien quand aucune session n’est proche' do
    travel_to(session_start - 5.days) { send_reminder }

    expect(parent.reload.calendly_last_booking_dates).to be_blank
  end
end
