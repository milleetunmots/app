require 'rails_helper'

RSpec.describe ChildSupport::CallerStopSupportService do
  context "when a caller stop support" do
    let!(:group) { FactoryBot.create(:group) }
    let!(:child) { FactoryBot.create(:child, group: group, group_status: 'active') }
    let!(:child_support) { child.child_support }
    let!(:supporter) { FactoryBot.create(:admin_user) }
    let!(:details) { Faker::Quote.famous_last_words }

    before(:each) do
      allow_any_instance_of(ProgramMessageService).to receive(:call).and_return(ProgramMessageService.new("01/01/2020", "12:30", [], ''))
    end

    subject { ChildSupport::CallerStopSupportService.new(supporter.id, child_support.id, 'program', details).call }
    before(:each) do
      subject
    end

    it "the supporter's id is added to the child_support's stop_support_caller_id" do
      expect(child_support.reload.stop_support_caller_id).to be supporter.id
    end

    it "today's date is added to the child_support's stop_support_date" do
      expect(child_support.reload.stop_support_date.to_date).to eq Time.zone.today
    end

    it "the details to child_support's stop_support_details" do
      expect(child_support.reload.stop_support_details).to eq details
    end

    it "the children's support are stopped" do
      expect(child.reload.group_status).to eq 'stopped'
      expect(child.reload.group_end).to eq Time.zone.today
    end
  end

  # Entre minuit et 1h à Paris, un serveur en UTC est encore la veille.
  # travel_to sur un instant UTC fige aussi DateTime.now et Time.now en UTC, comme sur un tel serveur.
  context "quand l'accompagnement est arrêté à 00h30, heure de Paris, sur un serveur en UTC" do
    let(:child) { FactoryBot.create(:child, group: FactoryBot.create(:group), group_status: 'active', should_contact_parent1: true) }
    let(:child_support) { child.child_support }
    let(:supporter) { FactoryBot.create(:admin_user) }
    let(:details) { 'Détails factuels' }

    before do
      FactoryBot.create(:media_text_messages_bundle, name: 'Arrêt · Famille pose problème / Inscrite sans accord / Ne veut pas du programme / Pratiques très avancées',
                        body1: 'Votre accompagnement s’arrête.', body2: nil, body3: nil)
                .update_column(:key, 'arret_accompagnement')
    end

    subject do
      travel_to(Time.utc(2027, 1, 11, 23, 30)) do
        ChildSupport::CallerStopSupportService.new(supporter.id, child_support.id, 'program', details).call
      end
    end

    it "date l'arrêt du jour de Paris" do
      subject

      expect(child_support.reload.stop_support_date.to_date).to eq Date.new(2027, 1, 12)
      expect(child_support.important_information).to include('Accompagnement arrêté le 12/01/2027')
      expect(child.reload.group_end).to eq Date.new(2027, 1, 12)
    end

    it "programme le SMS d'arrêt à l'heure de Paris" do
      expect(ProgramMessageService).to receive(:new).with('2027-01-12', '00:30', any_args).at_least(:once).and_call_original

      subject
    end
  end

  describe "message d'arrêt lu dans le trio du motif" do
    family_bundle = 'Arrêt · Famille pose problème / Inscrite sans accord / Ne veut pas du programme / Pratiques très avancées'
    health_professional_bundle = 'Arrêt · Professionnel·le de santé qui teste'
    language_barrier_bundle = 'Arrêt · Pas assez francophone'

    def campaigns
      WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                              .select { |signature| signature.uri.path.start_with?('/api/envoyer/') }
                              .map { |signature| URI.decode_www_form(signature.body).to_h }
    end

    def stop_bundle(name, key)
      FactoryBot.create(:media_text_messages_bundle, name: name, body1: "Texte du trio #{name}", body2: nil, body3: nil).tap { |bundle| bundle.update_column(:key, key) }
    end

    def lea(contact_parent: true)
      group = FactoryBot.create(:group, started_at: Time.zone.today.prev_occurring(:monday) - 8.weeks)
      FactoryBot.create(:child, first_name: 'Léa', group: group, group_status: 'active', should_contact_parent1: contact_parent).tap do
        WebMock::RequestRegistry.instance.reset!
      end
    end

    def stop(child, reason)
      marie = FactoryBot.create(:admin_user, user_role: 'caller', name: 'Marie')
      described_class.new(marie.id, child.child_support_id, reason, 'Détails factuels').call
    end

    {
      'program' => family_bundle,
      'very_advanced_practices' => family_bundle,
      'problematic_case' => family_bundle,
      'registered_by_partner_without_consent' => family_bundle,
      'professional' => health_professional_bundle,
      'family_limited_french_for_support' => language_barrier_bundle,
      'family_unresponsive_after_adaptation' => language_barrier_bundle
    }.each do |reason, bundle_name|
      it "envoie au parent de Léa le texte du trio « #{bundle_name} » pour le motif #{reason}" do
        stop_bundle(family_bundle, 'arret_accompagnement')
        stop_bundle(health_professional_bundle, 'arret_professionnel_sante')
        stop_bundle(language_barrier_bundle, 'arret_barriere_langue')
        child = lea

        service = stop(child, reason)

        expect(service.error).to be_nil
        expect(campaigns.map { |campaign| campaign['fallback_message'] || campaign['message'] }).to eq(["Texte du trio #{bundle_name}"])
      end
    end

    it 'arrête Léa sans message et signale le nom et la clé quand le trio du motif est introuvable' do
      child = lea
      expect(Rollbar).to receive(:error).with(a_string_including(language_barrier_bundle, 'arret_barriere_langue'))

      service = stop(child, 'family_limited_french_for_support')

      expect(service.error).to be_nil
      expect(child.reload).to have_attributes(group_status: 'stopped', group_end: Time.zone.today)
      expect(child.child_support.reload.tag_list).to include('arrêt accompagnante - non francophone')
      expect(campaigns).to be_empty
    end

    it "arrête Léa sans message quand aucun parent n'est à contacter" do
      stop_bundle(family_bundle, 'arret_accompagnement')
      child = lea(contact_parent: false)

      service = stop(child, 'program')

      expect(service.error).to be_nil
      expect(child.reload).to have_attributes(group_status: 'stopped', group_end: Time.zone.today)
      expect(campaigns).to be_empty
    end
  end
end
