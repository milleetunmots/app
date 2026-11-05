require 'rails_helper'

# Plages de RDV par session d'appel : l'état de chaque ligne passe par des classes
# (couleurs dans admin/call_session_date_overrides.sass), plus par des styles en ligne
RSpec.describe 'Réglages de RDV - plages par session d’appel', type: :request do
  let(:caller_user) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let(:group) { FactoryBot.create(:group, is_programmed: false) }

  before do
    # set_calls_dates recalcule les dates à la création : elles sont posées ensuite
    group.update!(
      call0_start_date: Date.current + 30.days, call0_end_date: Date.current + 40.days,
      call1_start_date: Date.current + 6.days, call1_end_date: Date.current + 16.days,
      call2_start_date: Date.current + 60.days, call2_end_date: Date.current + 70.days,
      call3_start_date: nil, call3_end_date: nil
    )
    caller_user.update!(group_subscriptions: { group.id.to_s => 5 })
    FactoryBot.create(:call_session_date_override, admin_user: caller_user, group: group.reload, call_session: 2)
    sign_in caller_user

    get '/admin/reglages_de_rdv'
  end

  def ligne(call_session)
    Capybara.string(response.body).find('tr', text: "Appel #{call_session} - #{group.name}")
  end

  it 'laisse neutre une session lointaine sans plage enregistrée' do
    expect(ligne(0)).to have_css('td.call-session-override-border:not(.call-session-override-border--alert):not(.call-session-override-border--persisted)')
    expect(ligne(0)).to have_css('strong.call-session-override-modification-deadline:not(.call-session-override-modification-deadline--alert)')
  end

  it 'signale une session dont la date limite de modification approche' do
    expect(ligne(1)).to have_css('td.call-session-override-border--alert[data-alert="true"]')
    expect(ligne(1)).to have_css('strong.call-session-override-modification-deadline--alert')
  end

  it 'marque une plage enregistrée' do
    expect(ligne(2)).to have_css('td.call-session-override-border--persisted')
    expect(ligne(2)).to have_css('a.reset-call-session-override--persisted')
  end

  it "n'écrit plus de couleur en ligne" do
    expect(Capybara.string(response.body).find('.call-session-date-overrides-panel table').native.to_html).not_to match(/color:|border-left/)
  end
end
