require 'rails_helper'

RSpec.describe Parent::SendSameDayScheduledCallReminderService do
  def campaigns
    WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                            .select { |signature| signature.uri.path.start_with?('/api/envoyer/') }
                            .map { |signature| URI.decode_www_form(signature.body).to_h.merge('raw' => signature.body) }
  end

  def reminder_bundle(body)
    FactoryBot.create(:media_text_messages_bundle, name: 'Rappel de RDV — jour J (~2h avant)', body1: body, body2: nil, body3: nil).tap { |bundle| bundle.update_column(:key, 'rappel_rdv_jour_j') }
  end

  def lucas_appointment_with_marie(at)
    child = FactoryBot.create(:child, first_name: 'Lucas', group: FactoryBot.create(:group), group_status: 'active')
    child.child_support.update!(supporter: FactoryBot.create(:admin_user, user_role: 'caller', name: 'Marie'))
    FactoryBot.create(:scheduled_call, parent: child.parent1, child_support: child.child_support, scheduled_at: Time.zone.parse(at))
    WebMock::RequestRegistry.instance.reset!
    child
  end

  around { |example| travel_to(Time.zone.parse('2027-03-02 10:00')) { example.run } }

  it "envoie au parent de Lucas le texte du trio « Rappel de RDV — jour J (~2h avant) », avec le prénom de Marie et l'heure du RDV" do
    reminder_bundle('RDV avec {PRENOM_ACCOMPAGNANTE} vers {RDV_CALENDLY_SCHEDULED_AT_HOUR} (Rappel de RDV — jour J (~2h avant))')
    lucas_appointment_with_marie('2027-03-02 12:30')

    service = described_class.new.call

    expect(service.errors).to be_empty
    expect(campaigns.size).to eq(1)
    expect(campaigns.first['fallback_message'] || campaigns.first['message']).to eq('RDV avec {PRENOM_ACCOMPAGNANTE} vers {RDV_CALENDLY_SCHEDULED_AT_HOUR} (Rappel de RDV — jour J (~2h avant))')
    expect(campaigns.first['raw']).to include('Marie', '12%3A30')
    expect(campaigns.first).not_to have_key('date')
  end

  it "n'envoie rien et signale le nom et la clé quand le trio du rappel est introuvable" do
    lucas_appointment_with_marie('2027-03-02 12:30')

    service = described_class.new.call

    expect(campaigns).to be_empty
    expect(service.errors).to include(a_string_including('Rappel de RDV — jour J (~2h avant)', 'rappel_rdv_jour_j'))
  end

  it 'programme une campagne RCS single avec le modèle et le lien du trio' do
    previous = ENV.fetch('RCS_SINGLE_TEXT_ENABLED', nil)
    ENV['RCS_SINGLE_TEXT_ENABLED'] = 'true'
    video = FactoryBot.create(:media_video, name: "Préparer l'appel")
    bundle = reminder_bundle("RDV avec {PRENOM_ACCOMPAGNANTE} vers {RDV_CALENDLY_SCHEDULED_AT_HOUR}. #{'a' * 200}")
    bundle.update_columns(link1_id: video.id, rcs_media1_id: 4523, rcs_text_template1: true)
    child = lucas_appointment_with_marie('2027-03-02 12:30')

    described_class.new.call

    expect(campaigns.first).to include('rcs_type' => 'single', 'media_id' => '4523')
    expect(RedirectionUrl.find_by(parent: child.parent1).redirection_target.medium).to eq(video)
  ensure
    previous.nil? ? ENV.delete('RCS_SINGLE_TEXT_ENABLED') : ENV['RCS_SINGLE_TEXT_ENABLED'] = previous
  end
end
