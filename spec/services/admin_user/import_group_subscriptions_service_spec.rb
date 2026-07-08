require 'rails_helper'

RSpec.describe AdminUser::ImportGroupSubscriptionsService do
  let(:future_monday) { (Date.current + 8.weeks).next_occurring(:monday) }
  let!(:admin_user) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let!(:group) { FactoryBot.create(:group, name: 'Septembre26-A', started_at: future_monday) }

  def airtable_registration(cohort_id: 'recCohortA', caller_id: 'recCaller1', families_count: 9, registration_id: 'INSC | Septembre26-A | Test')
    instance_double(Airtables::GroupSubscription,
                    airtable_cohort_id: cohort_id,
                    airtable_caller_id: caller_id,
                    families_count: families_count,
                    registration_id: registration_id)
  end

  def stub_airtable(registrations:, cohorts: { 'recCohortA' => 'Septembre26-A' }, cohort_start_dates: {}, callers: { 'recCaller1' => admin_user.id })
    cohort_doubles = cohorts.map do |id, name|
      instance_double(Airtables::Group, id: id, name: name, start_date: (cohort_start_dates[id] || future_monday).to_s)
    end
    allow(Airtables::GroupSubscription).to receive(:validated).and_return(registrations)
    allow(Airtables::Group).to receive(:all).and_return(cohort_doubles)
    allow(Airtables::Caller).to receive(:caller_id_by_airtable_caller_id) { |airtable_caller_id| callers[airtable_caller_id] }
  end

  describe '#call' do
    it 'enregistre les positionnements validés sur les cohortes futures' do
      stub_airtable(registrations: [airtable_registration(families_count: 9)])

      described_class.new.call

      expect(admin_user.reload.group_subscriptions).to eq({ group.id.to_s => 9 })
    end

    it 'met à jour le nombre de familles quand il change' do
      admin_user.update!(group_subscriptions: { group.id.to_s => 5 })
      stub_airtable(registrations: [airtable_registration(families_count: 12)])

      described_class.new.call

      expect(admin_user.reload.group_subscriptions).to eq({ group.id.to_s => 12 })
    end

    context "quand l'accompagnante n'est plus positionnée sur une cohorte" do
      let!(:override) { FactoryBot.create(:call_session_date_override, admin_user: admin_user, group: group) }
      let!(:other_admin_user) { FactoryBot.create(:admin_user, user_role: 'caller') }
      let!(:other_group) { FactoryBot.create(:group, name: 'Octobre26-A', started_at: future_monday) }

      before { admin_user.update!(group_subscriptions: { group.id.to_s => 5 }) }

      # Un autre positionnement, sans rapport, reste présent dans l'import pour que celui-ci
      # ne soit pas totalement vide (voir garde-fou anti-vidage plus bas dans le fichier).
      def stub_airtable_with_unrelated_registration
        stub_airtable(
          registrations: [airtable_registration(cohort_id: 'recCohortB', caller_id: 'recCaller2', families_count: 3)],
          cohorts: { 'recCohortB' => 'Octobre26-A' },
          callers: { 'recCaller2' => other_admin_user.id }
        )
      end

      it 'supprime le positionnement et les plages personnalisées si aucune famille ne lui est attribuée' do
        stub_airtable_with_unrelated_registration

        described_class.new.call

        expect(admin_user.reload.group_subscriptions).to eq({})
        expect(CallSessionDateOverride.where(admin_user: admin_user, group: group)).to be_empty
      end

      it 'conserve les plages personnalisées si des familles lui sont attribuées' do
        child = FactoryBot.create(:child, group: group, group_status: 'active')
        child.child_support.update!(supporter: admin_user)
        stub_airtable_with_unrelated_registration

        described_class.new.call

        expect(admin_user.reload.group_subscriptions).to eq({})
        expect(CallSessionDateOverride.where(admin_user: admin_user, group: group)).to contain_exactly(override)
      end

      it 'conserve les plages personnalisées si le groupe vient d\'être programmé' do
        group.update!(is_programmed: true)
        stub_airtable_with_unrelated_registration

        described_class.new.call

        expect(admin_user.reload.group_subscriptions).to eq({})
        expect(CallSessionDateOverride.where(admin_user: admin_user, group: group)).to contain_exactly(override)
      end
    end

    it "ignore l'import par sécurité si Airtable ne renvoie aucun positionnement alors que des positionnements existent" do
      admin_user.update!(group_subscriptions: { group.id.to_s => 5 })
      stub_airtable(registrations: [])

      service = described_class.new.call

      expect(service.errors).to include(a_string_matching(/import ignoré par sécurité/))
      expect(admin_user.reload.group_subscriptions).to eq({ group.id.to_s => 5 })
    end

    it "signale une erreur sans faire échouer tout l'import quand Airtable renvoie une erreur pour une accompagnante" do
      stub_airtable(registrations: [airtable_registration])
      allow(Airtables::Caller).to receive(:caller_id_by_airtable_caller_id).and_raise(Airrecord::Error, 'HTTP 404: not found')

      service = described_class.new.call

      expect(service.errors).to include(a_string_matching(/Erreur Airtable/))
      expect(admin_user.reload.group_subscriptions).to eq({})
    end

    it "signale une erreur et ignore l'inscription quand l'accompagnante est introuvable dans la base" do
      stub_airtable(registrations: [airtable_registration], callers: {})

      service = described_class.new.call

      expect(service.errors).to include(a_string_matching(/Accompagnante introuvable/))
      expect(admin_user.reload.group_subscriptions).to eq({})
    end

    it "signale une erreur et ignore l'inscription quand la cohorte n'existe pas dans l'application" do
      stub_airtable(registrations: [airtable_registration(cohort_id: 'recCohortZ')], cohorts: { 'recCohortZ' => 'Inconnue26-Z' })

      service = described_class.new.call

      expect(service.errors).to include(a_string_matching(/Cohorte introuvable/))
      expect(admin_user.reload.group_subscriptions).to eq({})
    end

    it 'ignore silencieusement les cohortes déjà programmées' do
      group.update!(is_programmed: true)
      stub_airtable(registrations: [airtable_registration])

      service = described_class.new.call

      expect(service.errors).to be_empty
      expect(admin_user.reload.group_subscriptions).to eq({})
    end

    it 'ignore silencieusement les cohortes déjà démarrées' do
      past_group = FactoryBot.create(:group, name: 'Janvier26-A', started_at: (Date.current - 8.weeks).next_occurring(:monday))
      stub_airtable(
        registrations: [airtable_registration(cohort_id: 'recCohortP')],
        cohorts: { 'recCohortP' => 'Janvier26-A' },
        cohort_start_dates: { 'recCohortP' => Date.current - 8.weeks }
      )

      service = described_class.new.call

      expect(service.errors).to be_empty
      expect(admin_user.reload.group_subscriptions).to eq({})
      expect(past_group.reload).to be_present
    end

    it "rattache la cohorte au groupe malgré des différences d'espacement dans le nom" do
      group.update!(name: 'Juin 26 - A')
      stub_airtable(registrations: [airtable_registration(families_count: 7)], cohorts: { 'recCohortA' => 'Juin26-A' })

      service = described_class.new.call

      expect(service.errors).to be_empty
      expect(admin_user.reload.group_subscriptions).to eq({ group.id.to_s => 7 })
    end
  end
end
