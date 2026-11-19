require 'rails_helper'

RSpec.describe Parent::IdentifyCalendlyInviteeService do
  let(:event_type_uri) { 'https://api.calendly.com/event_types/M1' }

  def invitee_payload(tracking = {}, scheduled_event: nil, email: nil, name: nil)
    payload = { 'event' => 'https://api.calendly.com/scheduled_events/RDV-1', 'tracking' => tracking }
    payload['scheduled_event'] = scheduled_event if scheduled_event
    payload['email'] = email if email
    payload['name'] = name if name
    payload
  end

  def identify(payload)
    described_class.new(invitee_payload: payload).call
  end

  describe '#call' do
    context 'avec le jeton complet' do
      it 'identifie le parent et la session du lien' do
        parent = FactoryBot.create(:parent)

        service = identify(invitee_payload({ 'utm_campaign' => 'call2', 'utm_content' => parent.security_token }))

        expect(service.errors).to be_empty
        expect(service.parent).to eq(parent)
        expect(service.call_session).to eq(2)
      end

      it 'ignore les caractères non alphanumériques ajoutés au jeton' do
        parent = FactoryBot.create(:parent)

        service = identify(invitee_payload({ 'utm_campaign' => 'call1', 'utm_content' => "#{parent.security_token}." }))

        expect(service.parent).to eq(parent)
      end

      it 'ignore les parents archivés' do
        parent = FactoryBot.create(:parent)
        parent.discard

        service = identify(invitee_payload({ 'utm_content' => parent.security_token }))

        expect(service.parent).to be_nil
        expect(service.errors).to contain_exactly(hash_including(message: 'Aucun parent identifié pour ce RDV'))
      end
    end

    context 'sans jeton exploitable ni lien reconnu' do
      it 'renvoie une erreur avec le contexte du RDV' do
        payload = invitee_payload(
          { 'utm_campaign' => nil, 'utm_content' => 'ffffffff' },
          scheduled_event: {
            'event_type' => 'https://api.calendly.com/event_types/INCONNU',
            'event_memberships' => [{ 'user' => 'https://api.calendly.com/users/AWA' }]
          }
        )

        service = identify(payload)

        expect(service.parent).to be_nil
        expect(service.errors).to eq(
          [{
            message: 'Aucun parent identifié pour ce RDV',
            context: {
              event_uri: 'https://api.calendly.com/scheduled_events/RDV-1',
              event_type_uri: 'https://api.calendly.com/event_types/INCONNU',
              host_uris: ['https://api.calendly.com/users/AWA'],
              security_token: 'ffffffff'
            }
          }]
        )
      end

      it 'renvoie la même erreur quand le payload ne contient ni tracking ni scheduled_event' do
        service = identify({ 'event' => 'https://api.calendly.com/scheduled_events/RDV-1' })

        expect(service.parent).to be_nil
        expect(service.errors).to contain_exactly(hash_including(message: 'Aucun parent identifié pour ce RDV'))
      end
    end

    context 'avec un jeton absent, tronqué ou inconnu' do
      let!(:parent) { FactoryBot.create(:parent, calendly_one_off_event_type_uris: { event_type_uri => 1 }) }

      [nil, '--', 'TRUNCATED', 'ffffffffffffffffffffffffffffffff'].each do |utm_content|
        it "se rabat sur le lien réservé (utm_content #{utm_content.inspect})" do
          utm_content = parent.security_token.first(10) if utm_content == 'TRUNCATED'

          service = identify(invitee_payload({ 'utm_content' => utm_content }, scheduled_event: { 'event_type' => event_type_uri }))

          expect(service.errors).to be_empty
          expect(service.parent).to eq(parent)
          expect(service.call_session).to eq(1)
        end
      end
    end

    context 'avec le lien réservé' do
      it 'reconnaît un lien remplacé depuis par un lien plus récent' do
        parent = FactoryBot.create(:parent, calendly_one_off_event_type_uris: { event_type_uri => 1, "#{event_type_uri}-BIS" => 1 })

        service = identify(invitee_payload(scheduled_event: { 'event_type' => event_type_uri }))

        expect(service.parent).to eq(parent)
        expect(service.call_session).to eq(1)
      end

      it "n'identifie personne pour un lien inconnu" do
        FactoryBot.create(:parent, calendly_one_off_event_type_uris: { event_type_uri => 1 })

        service = identify(invitee_payload(scheduled_event: { 'event_type' => 'https://api.calendly.com/event_types/AUTRE' }))

        expect(service.parent).to be_nil
        expect(service.errors).to contain_exactly(hash_including(message: 'Aucun parent identifié pour ce RDV'))
      end

      it 'ignore les parents archivés' do
        FactoryBot.create(:parent, calendly_one_off_event_type_uris: { event_type_uri => 1 }).discard

        service = identify(invitee_payload(scheduled_event: { 'event_type' => event_type_uri }))

        expect(service.parent).to be_nil
      end
    end

    context 'avec le lien réservé et les informations saisies' do
      let!(:link_parent) do
        FactoryBot.create(:parent, first_name: 'Mariam', last_name: 'Diallo-Sow', email: 'mariam.diallo@example.com',
                                   calendly_one_off_event_type_uris: { event_type_uri => 1 })
      end

      def booking(email: 'autre@example.com', name: 'Inconnu')
        identify(invitee_payload(scheduled_event: { 'event_type' => event_type_uri }, email: email, name: name))
      end

      it "confirme le parent par l'e-mail, sans tenir compte de la casse ni des espaces" do
        service = booking(email: ' Mariam.Diallo@Example.com ', name: 'M. D.')

        expect(service.errors).to be_empty
        expect(service.parent).to eq(link_parent)
      end

      [
        ['Mariam Diallo-Sow', true], ['DIALLO SOW', true], ['Diallosow', true], ['Mariam Diallô Sow', true],
        ['Diallo', false], ['Sow', false], ['Mariam', false], ['Mariam Sow-Diallo', false], ['Jean Martin', false]
      ].each do |name, confirmed|
        it "#{confirmed ? 'confirme' : 'ne confirme pas'} le parent avec le nom saisi #{name.inspect}" do
          service = booking(name: name)

          expect(service.parent).to eq(confirmed ? link_parent : nil)
        end
      end

      it 'ne confirme pas un nom de famille court contenu dans un autre mot' do
        link_parent.update!(last_name: 'Li')

        expect(booking(name: 'Olivier Dupont').parent).to be_nil
      end

      it "garde le lien seul quand l'e-mail est prérempli et le nom vide" do
        service = booking(email: 'rdv@1001mots.org', name: '')

        expect(service.errors).to be_empty
        expect(service.parent).to eq(link_parent)
      end

      it 'renvoie une erreur, sans e-mail ni nom dans le contexte, quand rien ne correspond' do
        service = booking(email: 'jean.martin@example.com', name: 'Jean Martin')

        expect(service.parent).to be_nil
        expect(service.errors).to eq(
          [{
            message: 'Les informations saisies ne correspondent à aucun parent de la fiche de suivi du lien',
            context: {
              parent_id: link_parent.id,
              event_type_uri: event_type_uri,
              event_uri: 'https://api.calendly.com/scheduled_events/RDV-1'
            }
          }]
        )
      end

      context "quand l'autre parent de la fiche de suivi réserve sur le lien" do
        let!(:other_parent) do
          FactoryBot.create(:parent, first_name: 'Paul', last_name: 'Martin', email: 'paul.martin@example.com')
        end

        before { FactoryBot.create(:child, parent1: link_parent, parent2: other_parent) }

        it "attribue le RDV à l'autre parent, reconnu par son nom, avec la session du lien" do
          service = booking(name: 'Paul Martin')

          expect(service.errors).to be_empty
          expect(service.parent).to eq(other_parent)
          expect(service.call_session).to eq(1)
        end

        it "attribue le RDV à l'autre parent, reconnu par son e-mail" do
          expect(booking(email: 'paul.martin@example.com').parent).to eq(other_parent)
        end

        it 'privilégie le parent du lien quand les deux correspondent' do
          other_parent.update!(last_name: 'Diallo-Sow')

          expect(booking(name: 'Diallo-Sow').parent).to eq(link_parent)
        end

        it "ne confirme pas un parent d'une autre famille" do
          FactoryBot.create(:parent, last_name: 'Durand')

          expect(booking(name: 'Durand').parent).to be_nil
        end
      end
    end

    context 'pour retrouver la session d’appel' do
      # sessions : 0 du 05/01 au 18/01, 1 du 02/02 au 15/02, 2 du 02/03 au 22/03, 3 du 01/06 au 28/06
      let(:group) { FactoryBot.create(:group, started_at: Date.new(2026, 1, 5)) }
      let!(:parent) { FactoryBot.create(:parent) }
      let!(:child) { FactoryBot.create(:child, parent1: parent, group: group, group_status: 'active') }

      def booking_at(start_time, tracking = { 'utm_content' => parent.security_token })
        identify(invitee_payload(tracking, scheduled_event: { 'event_type' => event_type_uri, 'start_time' => start_time }))
      end

      it "prend la session enregistrée pour le lien plutôt qu'utm_campaign" do
        parent.update!(calendly_one_off_event_type_uris: { event_type_uri => 1 })

        service = booking_at('2026-01-10T09:00:00Z', 'utm_campaign' => 'call3', 'utm_content' => parent.security_token)

        expect(service.call_session).to eq(1)
      end

      it "prend utm_campaign quand le lien n'est pas enregistré" do
        service = booking_at('2026-01-10T09:00:00Z', 'utm_campaign' => 'call3', 'utm_content' => parent.security_token)

        expect(service.call_session).to eq(3)
      end

      it 'déduit la session des dates de la cohorte sans lien enregistré ni utm_campaign' do
        expect(booking_at('2026-03-10T09:00:00Z').call_session).to eq(2)
      end

      it "prend la session la plus proche quand le RDV tombe entre deux périodes d'appel" do
        expect(booking_at('2026-01-22T09:00:00Z').call_session).to eq(0)
        expect(booking_at('2026-01-30T09:00:00Z').call_session).to eq(1)
      end

      it 'laisse la session vide sans date de RDV ni cohorte' do
        child.update!(group: nil, group_status: 'waiting')

        expect(booking_at('2026-03-10T09:00:00Z').call_session).to be_nil
        expect(identify(invitee_payload({ 'utm_content' => parent.security_token })).call_session).to be_nil
      end

      [['call0', 0], ['call3', 3], ['autre', nil], [nil, nil]].each do |utm_campaign, expected_session|
        it "déduit la session #{expected_session.inspect} de utm_campaign #{utm_campaign.inspect}" do
          service = identify(invitee_payload({ 'utm_campaign' => utm_campaign, 'utm_content' => parent.security_token }))

          expect(service.call_session).to eq(expected_session)
        end
      end
    end
  end
end
