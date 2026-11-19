require 'rails_helper'

RSpec.describe Parent::SendNextDayScheduledCallReminderService do
  def campaigns
    WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                            .select { |signature| signature.uri.path.start_with?('/api/envoyer/') }
                            .map { |signature| URI.decode_www_form(signature.body).to_h.merge('raw' => signature.body) }
  end

  def reminder_bundle(body)
    FactoryBot.create(:media_text_messages_bundle, name: 'Rappel de RDV — la veille (J-1)', body1: body, body2: nil, body3: nil).tap { |bundle| bundle.update_column(:key, 'rappel_rdv_veille') }
  end

  def lucas_appointment_with_marie(at)
    child = FactoryBot.create(:child, first_name: 'Lucas', group: FactoryBot.create(:group), group_status: 'active')
    child.child_support.update!(supporter: FactoryBot.create(:admin_user, user_role: 'caller', name: 'Marie'))
    FactoryBot.create(:scheduled_call, parent: child.parent1, child_support: child.child_support, scheduled_at: Time.zone.parse(at))
    WebMock::RequestRegistry.instance.reset!
    child
  end

  around { |example| travel_to(Time.zone.parse('2027-03-02 09:00')) { example.run } }

  it "envoie au parent de Lucas le texte du trio « Rappel de RDV — la veille (J-1) », avec le prénom de Marie et l'heure du RDV" do
    reminder_bundle('RDV avec {PRENOM_ACCOMPAGNANTE} vers {RDV_CALENDLY_SCHEDULED_AT_HOUR} (Rappel de RDV — la veille (J-1))')
    lucas_appointment_with_marie('2027-03-03 14:30')

    service = described_class.new.call

    expect(service.errors).to be_empty
    expect(campaigns.size).to eq(1)
    expect(campaigns.first['fallback_message'] || campaigns.first['message']).to eq('RDV avec {PRENOM_ACCOMPAGNANTE} vers {RDV_CALENDLY_SCHEDULED_AT_HOUR} (Rappel de RDV — la veille (J-1))')
    expect(campaigns.first['raw']).to include('Marie', '14%3A30')
    expect(campaigns.first).not_to have_key('date')
  end

  it "n'envoie rien et signale le nom et la clé quand le trio du rappel est introuvable" do
    lucas_appointment_with_marie('2027-03-03 14:30')

    service = described_class.new.call

    expect(campaigns).to be_empty
    expect(service.errors).to include(a_string_including('Rappel de RDV — la veille (J-1)', 'rappel_rdv_veille'))
  end

  it "ne cherche aucun trio et n'émet aucune alerte quand aucun RDV n'est prévu le lendemain" do
    service = described_class.new.call

    expect(campaigns).to be_empty
    expect(service.errors).to be_empty
  end

  it 'programme une campagne RCS single avec le modèle et le lien du trio' do
    previous = ENV.fetch('RCS_SINGLE_TEXT_ENABLED', nil)
    ENV['RCS_SINGLE_TEXT_ENABLED'] = 'true'
    video = FactoryBot.create(:media_video, name: "Préparer l'appel")
    bundle = reminder_bundle("RDV avec {PRENOM_ACCOMPAGNANTE} vers {RDV_CALENDLY_SCHEDULED_AT_HOUR}. #{'a' * 200}")
    bundle.update_columns(link1_id: video.id, rcs_media1_id: 4522, rcs_text_template1: true)
    child = lucas_appointment_with_marie('2027-03-03 14:30')

    described_class.new.call

    expect(campaigns.first).to include('rcs_type' => 'single', 'media_id' => '4522')
    expect(RedirectionUrl.find_by(parent: child.parent1).redirection_target.medium).to eq(video)
  ensure
    previous.nil? ? ENV.delete('RCS_SINGLE_TEXT_ENABLED') : ENV['RCS_SINGLE_TEXT_ENABLED'] = previous
  end
end
