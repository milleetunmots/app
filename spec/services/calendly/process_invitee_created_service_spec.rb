require 'rails_helper'

RSpec.describe Calendly::ProcessInviteeCreatedService do
  let(:calendly_event_type_uri) { 'https://api.calendly.com/event_types/abc123' }
  let(:calendly_event_type_uris) { { 'call0' => calendly_event_type_uri, 'call1' => calendly_event_type_uri } }
  let!(:admin_user) { FactoryBot.create(:admin_user) }
  let!(:parent) { FactoryBot.create(:parent) }
  let!(:child) { FactoryBot.create(:child, parent1: parent) }
  let!(:child_support) do
    child_support = child.child_support
    child_support.update!(supporter: admin_user)
    child_support
  end

  let(:event_uri) { 'https://api.calendly.com/scheduled_events/event123' }
  let(:invitee_uri) { 'https://api.calendly.com/scheduled_events/event123/invitees/invitee456' }

  let(:payload) do
    {
      'event' => 'invitee.created',
      'payload' => {
        'event' => event_uri,
        'uri' => invitee_uri,
        'cancel_url' => 'https://calendly.com/cancellations/abc123',
        'email' => 'parent@example.com',
        'name' => 'Test Parent',
        'tracking' => {
          'utm_source' => '1001mots',
          'utm_campaign' => 'call0',
          'utm_content' => parent.security_token
        },
        'questions_and_answers' => [
          { 'question' => 'Commentaire', 'answer' => 'Test comment' }
        ],
        # structure relevée sur un webhook de production (05/11/2026), valeurs anonymisées
        'scheduled_event' => {
          'uri' => event_uri,
          'event_type' => calendly_event_type_uri,
          'event_memberships' => [{ 'user' => 'https://api.calendly.com/users/AWA' }],
          'location' => { 'location' => '+33700000000', 'type' => 'inbound_call' },
          'start_time' => '2026-01-15T10:00:00.000000Z',
          'end_time' => '2026-01-15T10:30:00.000000Z'
        }
      }
    }
  end

  let(:scheduled_event_response) do
    {
      'resource' => {
        'uri' => event_uri,
        'name' => 'Appel 0 - Test',
        'start_time' => '2026-01-15T10:00:00Z',
        'end_time' => '2026-01-15T10:30:00Z',
        'event_type' => calendly_event_type_uri,
        'status' => 'active'
      }
    }
  end

  subject { described_class.new(payload: payload) }

  before do
    stub_request(:get, event_uri)
      .to_return(status: 200, body: scheduled_event_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, event_uri)
      .to_return(status: 200, body: scheduled_event_response.to_json, headers: { 'Content-Type' => 'application/json' })

    program_message_service = instance_double(ProgramMessageService, call: nil, errors: [])
    allow(ProgramMessageService).to receive(:new).and_return(program_message_service)
    allow(program_message_service).to receive(:call).and_return(program_message_service)
  end

  describe '#call' do
    context 'when payload is valid' do
      it 'creates a new ScheduledCall' do
        expect { subject.call }.to change(ScheduledCall, :count).by(1)
      end

      it 'returns self with no errors' do
        result = subject.call
        expect(result.errors).to be_empty
      end

      it 'creates ScheduledCall with correct attributes' do
        result = subject.call
        scheduled_call = result.scheduled_call

        expect(scheduled_call.calendly_event_uri).to eq(event_uri)
        expect(scheduled_call.calendly_invitee_uri).to eq(invitee_uri)
        expect(scheduled_call.admin_user).to eq(admin_user)
        expect(scheduled_call.child_support).to eq(child_support)
        expect(scheduled_call.parent).to eq(parent)
        expect(scheduled_call.call_session).to eq(0)
        expect(scheduled_call.invitee_email).to eq('parent@example.com')
        expect(scheduled_call.invitee_name).to eq('Test Parent')
        expect(scheduled_call.status).to eq('scheduled')
      end

      it 'extracts event details from API' do
        result = subject.call
        scheduled_call = result.scheduled_call

        expect(scheduled_call.scheduled_at).to eq(Time.zone.parse('2026-01-15T10:00:00Z'))
        expect(scheduled_call.duration_minutes).to eq(30)
        expect(scheduled_call.event_type_name).to eq('Appel 0 - Test')
      end

      it 'extracts invitee comment from questions and answers' do
        result = subject.call
        expect(result.scheduled_call.invitee_comment).to include('Commentaire: Test comment')
      end

      it 'stores raw payload' do
        result = subject.call
        expect(result.scheduled_call.raw_payload).to eq(payload)
      end

      it "enregistre le type d'événement réservé" do
        result = subject.call
        expect(result.scheduled_call.event_type_uri).to eq(calendly_event_type_uri)
      end
    end

    context "avec un lien sans paramètres de suivi, identifié par son type d'événement" do
      it 'enregistre le RDV pour le parent et la session du lien, et envoie la confirmation' do
        parent.update!(calendly_one_off_event_type_uris: { calendly_event_type_uri => 1 })
        payload['payload']['tracking'] = { 'utm_campaign' => nil, 'utm_content' => nil }

        result = subject.call

        expect(result.errors).to be_empty
        expect(result.scheduled_call).to have_attributes(
          parent: parent, child_support: child_support, admin_user: admin_user,
          call_session: 1, event_type_uri: calendly_event_type_uri, status: 'scheduled'
        )
        expect(ProgramMessageService).to have_received(:new).with(anything, anything, ["parent.#{parent.id}"], anything)
      end

      it 'remplace le RDV actif de la même session' do
        parent.update!(calendly_one_off_event_type_uris: { calendly_event_type_uri => 0 })
        payload['payload']['tracking'] = {}
        replaced_call = ScheduledCall.create!(
          calendly_event_uri: 'https://api.calendly.com/scheduled_events/ANCIEN-RDV', status: 'scheduled',
          call_session: 0, child_support: child_support, parent: parent, scheduled_at: 2.days.from_now
        )
        stub_request(:post, 'https://api.calendly.com/scheduled_events/ANCIEN-RDV/cancellation')
          .to_return(status: 201, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

        subject.call

        expect(WebMock).to have_requested(:post, 'https://api.calendly.com/scheduled_events/ANCIEN-RDV/cancellation')
        expect(replaced_call.reload.status).to eq('canceled')
      end

      it "n'utilise pas le type d'événement quand le jeton complet est inconnu" do
        parent.update!(calendly_one_off_event_type_uris: { calendly_event_type_uri => 1 })
        payload['payload']['tracking']['utm_content'] = 'ffffffffffffffffffffffffffffffff'

        result = subject.call

        expect(result.errors).to include(hash_including(message: 'Aucun parent trouvé avec le security_token'))
        expect(result.scheduled_call).to be_nil
        expect(ProgramMessageService).not_to have_received(:new)
      end
    end

    context 'when security_token is missing' do
      before do
        admin_user.update!(calendly_user_uri: 'https://api.calendly.com/users/AWA')
        payload['payload']['tracking']['utm_content'] = nil
      end

      it "renvoie une erreur quand aucun autre moyen n'identifie le parent" do
        result = subject.call
        expect(result.errors).to include(hash_including(message: 'Aucun parent identifié pour ce RDV'))
      end

      it 'does not create a ScheduledCall' do
        expect { subject.call }.not_to change(ScheduledCall, :count)
      end
    end

    context "sans jeton ni type d'événement connu : recherche par e-mail puis par nom" do
      # session 1 du 10/11 au 23/11/2026 : le SMS de prise de RDV part à J-3
      def prepare_family_in_session
        admin_user.update!(calendly_user_uri: 'https://api.calendly.com/users/AWA')
        group = FactoryBot.create(:group, started_at: Date.new(2026, 10, 12))
        group.update_columns(
          call0_start_date: Date.new(2026, 10, 13), call0_end_date: Date.new(2026, 10, 26),
          call1_start_date: Date.new(2026, 11, 10), call1_end_date: Date.new(2026, 11, 23),
          call2_start_date: Date.new(2027, 1, 4), call2_end_date: Date.new(2027, 1, 17),
          call3_start_date: Date.new(2027, 3, 1), call3_end_date: Date.new(2027, 3, 14)
        )
        child.update!(group: group, group_status: 'active')
        parent.update!(email: 'mariam.diallo@example.com')
        payload['payload']['tracking'] = {}
        payload['payload']['email'] = 'mariam.diallo@example.com'
        payload['payload']['scheduled_event']['event_type'] = 'https://api.calendly.com/event_types/LIEN-ANTERIEUR'
      end

      it 'enregistre le RDV pour la session en cours et envoie la confirmation' do
        prepare_family_in_session

        result = travel_to(Time.zone.local(2026, 11, 8, 10)) { subject.call }

        expect(result.errors).to be_empty
        expect(result.scheduled_call).to have_attributes(
          parent: parent, child_support: child_support, admin_user: admin_user, call_session: 1
        )
        expect(ProgramMessageService).to have_received(:new).with(anything, anything, ["parent.#{parent.id}"], anything)
      end

      [
        [Date.new(2026, 11, 6), nil],
        [Date.new(2026, 11, 7), 1],
        [Date.new(2026, 11, 23), 1],
        [Date.new(2026, 11, 24), nil]
      ].each do |received_on, expected_session|
        it "#{expected_session ? 'rattache' : 'rejette'} un RDV reçu le #{received_on.strftime('%d/%m/%Y')}" do
          prepare_family_in_session

          result = travel_to(received_on.in_time_zone.change(hour: 10)) { subject.call }

          if expected_session
            expect(result.scheduled_call.call_session).to eq(expected_session)
          else
            expect(result.errors).to include(hash_including(message: "Aucune session d'appel en cours pour ce parent"))
            expect(ScheduledCall.count).to eq(0)
          end
        end
      end

      it "n'enregistre rien quand aucun parent ne correspond" do
        prepare_family_in_session
        payload['payload']['email'] = 'jean.martin@example.com'
        payload['payload']['name'] = 'Jean Martin'

        result = travel_to(Time.zone.local(2026, 11, 8, 10)) { subject.call }

        expect(result.errors).to include(hash_including(message: 'Aucun parent identifié pour ce RDV'))
        expect(ScheduledCall.count).to eq(0)
        expect(ProgramMessageService).not_to have_received(:new)
      end

      it "n'enregistre rien quand le compte Calendly hôte est inconnu" do
        prepare_family_in_session
        payload['payload']['scheduled_event']['event_memberships'] = [{ 'user' => 'https://api.calendly.com/users/INCONNU' }]

        result = travel_to(Time.zone.local(2026, 11, 8, 10)) { subject.call }

        expect(result.errors).to include(hash_including(message: "Aucune accompagnante n'a ce compte Calendly"))
        expect(ScheduledCall.count).to eq(0)
      end

      it "n'enregistre rien quand le webhook ne contient pas scheduled_event" do
        prepare_family_in_session
        payload['payload'].delete('scheduled_event')

        result = travel_to(Time.zone.local(2026, 11, 8, 10)) { subject.call }

        expect(result.errors).to include(hash_including(message: 'Aucun parent identifié pour ce RDV'))
        expect(ScheduledCall.count).to eq(0)
      end

      it "n'envoie qu'une confirmation quand le webhook est rejoué" do
        prepare_family_in_session

        travel_to(Time.zone.local(2026, 11, 8, 10)) do
          described_class.new(payload: payload).call
          described_class.new(payload: payload).call
        end

        expect(ScheduledCall.where(calendly_event_uri: event_uri).count).to eq(1)
        expect(ProgramMessageService).to have_received(:new).once
      end
    end

    context 'when parent is not found' do
      before do
        payload['payload']['tracking']['utm_content'] = 'ffffffffffffffffffffffffffffffff'
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: "Aucun parent trouvé avec le security_token"))
      end
    end

    context 'avec un jeton tronqué' do
      it 'enregistre le RDV pour le seul parent dont le jeton commence par ce morceau' do
        payload['payload']['tracking']['utm_content'] = parent.security_token.first(6)

        result = subject.call

        expect(result.errors).to be_empty
        expect(result.scheduled_call.parent).to eq(parent)
        expect(result.scheduled_call.call_session).to eq(0)
      end
    end

    context 'when parent has no current child with child_support' do
      before do
        parent.children.destroy_all
      end

      it 'returns an error about missing child support' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: "Aucune fiche de suivi trouvée pour ce parent"))
      end
    end

    context 'with different call sessions' do
      %w[call0 call1 call2 call3].each_with_index do |campaign, index|
        context "when utm_campaign is #{campaign}" do
          before do
            payload['payload']['tracking']['utm_campaign'] = campaign
          end

          it "extracts call_session as #{index}" do
            result = subject.call
            expect(result.scheduled_call.call_session).to eq(index)
          end
        end
      end
    end

    context 'when ScheduledCall already exists for event_uri' do
      let!(:existing_scheduled_call) do
        ScheduledCall.create!(
          calendly_event_uri: event_uri,
          status: 'scheduled'
        )
      end

      it 'updates the existing ScheduledCall' do
        expect { subject.call }.not_to change(ScheduledCall, :count)
      end

      it 'updates attributes on existing record' do
        subject.call
        existing_scheduled_call.reload
        expect(existing_scheduled_call.parent).to eq(parent)
        expect(existing_scheduled_call.child_support).to eq(child_support)
      end

      context 'when a duplicated webhook is received (Calendly retry)' do
        let!(:other_active_call) do
          ScheduledCall.create!(
            calendly_event_uri: 'https://api.calendly.com/scheduled_events/other_event',
            status: 'scheduled',
            call_session: 0,
            child_support: child_support,
            parent: parent
          )
        end

        it 'does not trigger a redundant replacement' do
          subject.call
          expect(other_active_call.reload.status).to eq('scheduled')
          expect(WebMock).not_to have_requested(:post, %r{/cancellation})
        end

        it 'does not resend the confirmation message' do
          subject.call
          expect(ProgramMessageService).not_to have_received(:new)
        end
      end
    end

    context 'when an active ScheduledCall exists for the same child_support and call_session' do
      let(:replaced_event_uri) { 'https://api.calendly.com/scheduled_events/replaced_event' }
      let!(:replaced_scheduled_call) do
        ScheduledCall.create!(
          calendly_event_uri: replaced_event_uri,
          status: 'scheduled',
          call_session: 0,
          child_support: child_support,
          parent: parent,
          scheduled_at: 2.days.from_now
        )
      end

      before do
        stub_request(:post, "#{replaced_event_uri}/cancellation")
          .to_return(status: 201, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'creates the new ScheduledCall with status scheduled' do
        result = subject.call
        expect(result.scheduled_call.status).to eq('scheduled')
        expect(result.scheduled_call.calendly_event_uri).to eq(event_uri)
      end

      it 'cancels the replaced event via the Calendly API' do
        subject.call
        expect(WebMock).to have_requested(:post, "#{replaced_event_uri}/cancellation")
      end

      it 'marks the replaced ScheduledCall as canceled' do
        subject.call
        replaced_scheduled_call.reload
        expect(replaced_scheduled_call.status).to eq('canceled')
        expect(replaced_scheduled_call.cancellation_reason).to eq(described_class::REPLACED_CANCELLATION_REASON)
      end

      it 'returns self with no errors' do
        result = subject.call
        expect(result.errors).to be_empty
      end

      context 'when the replaced call targets another call_session' do
        before do
          replaced_scheduled_call.update!(call_session: 1)
        end

        it 'does not cancel it' do
          subject.call
          expect(replaced_scheduled_call.reload.status).to eq('scheduled')
          expect(WebMock).not_to have_requested(:post, "#{replaced_event_uri}/cancellation")
        end
      end

      context 'when the replaced call belongs to another child_support' do
        let!(:other_parent) { FactoryBot.create(:parent) }
        let!(:other_child) { FactoryBot.create(:child, parent1: other_parent) }

        before do
          replaced_scheduled_call.update!(child_support: other_child.child_support)
        end

        it 'does not cancel it' do
          subject.call
          expect(replaced_scheduled_call.reload.status).to eq('scheduled')
          expect(WebMock).not_to have_requested(:post, "#{replaced_event_uri}/cancellation")
        end
      end

      context 'when the Calendly cancellation API fails' do
        before do
          stub_request(:post, "#{replaced_event_uri}/cancellation")
            .to_return(status: 500, body: { 'message' => 'Server error' }.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        # le créneau est toujours réservé côté Calendly : le laisser « scheduled »
        # localement reste l'état le plus fidèle, et l'accompagnante voit le conflit
        it 'leaves the replaced ScheduledCall scheduled locally' do
          subject.call
          expect(replaced_scheduled_call.reload.status).to eq('scheduled')
        end

        it 'reports the error' do
          result = subject.call
          expect(result.errors).to include(hash_including(
            message: "L'annulation sur Calendly du RDV remplacé a échoué",
            scheduled_call_id: replaced_scheduled_call.id
          ))
        end
      end
    end

    context 'when API call to fetch event details fails' do
      before do
        stub_request(:get, event_uri)
          .to_return(status: 404, body: { 'message' => 'Not found' }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'still creates the ScheduledCall with available data' do
        expect { subject.call }.to change(ScheduledCall, :count).by(1)
      end

      it 'logs the API error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: "Échec de la récupération de l'événement"))
      end

      context 'when child_support has a supporter' do
        let(:supporter) { FactoryBot.create(:admin_user) }

        before do
          child_support.update!(supporter: supporter)
        end

        it 'uses the supporter as admin_user fallback' do
          result = subject.call
          expect(result.scheduled_call.admin_user).to eq(supporter)
        end
      end
    end

    context 'when questions_and_answers is empty' do
      before do
        payload['payload']['questions_and_answers'] = []
      end

      it 'creates ScheduledCall with nil invitee_comment' do
        result = subject.call
        expect(result.scheduled_call.invitee_comment).to be_nil
      end
    end

    context 'when questions_and_answers has multiple entries' do
      before do
        payload['payload']['questions_and_answers'] = [
          { 'question' => 'Question 1', 'answer' => 'Answer 1' },
          { 'question' => 'Question 2', 'answer' => 'Answer 2' }
        ]
      end

      it 'concatenates all questions and answers' do
        result = subject.call
        expect(result.scheduled_call.invitee_comment).to include('Question 1: Answer 1')
        expect(result.scheduled_call.invitee_comment).to include('Question 2: Answer 2')
      end
    end
  end
end
