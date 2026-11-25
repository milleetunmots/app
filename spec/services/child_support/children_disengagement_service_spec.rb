require 'rails_helper'

RSpec.describe ChildSupport::ChildrenDisengagementService do
  describe '#call' do
    let(:supporter) { FactoryBot.create(:admin_user, user_role: 'caller', name: 'Marie')}
    let!(:group) { FactoryBot.create(:group, type_of_support: 'with_calls') }

    let!(:child_to_conserve) { FactoryBot.create(:child, group: group, group_status: 'active') }
    let!(:child_support_to_conserve) { child_to_conserve.child_support.tap { |cs| cs.update!(supporter: supporter, call0_status: 'OK', call1_status: 'KO') } }

    let!(:disengaged_child) { FactoryBot.create(:child, group: group, group_status: 'active', first_name: 'Lucas') }
    let!(:disengaged_child_support) { disengaged_child.child_support.tap { |cs| cs.update!(supporter: supporter, call0_status: 'KO', call1_status: 'KO') } }


    let!(:first_disengaged_child_in_siblings) { FactoryBot.create(:child, group: group, group_status: 'active', birthdate: 1.year.ago) }
    let!(:second_disengaged_child_in_siblings) { FactoryBot.create(:child, parent1: first_disengaged_child_in_siblings.parent1, group: group, group_status: 'active', birthdate: first_disengaged_child_in_siblings.birthdate + 2.days) }
    let!(:siblings_child_support) { first_disengaged_child_in_siblings.child_support.tap { |cs| cs.update!(supporter: supporter, call0_status: 'Ne pas appeler', call1_status: 'KO') } }

    before(:each) do
      allow_any_instance_of(ProgramMessageService).to receive(:call).and_return(double(errors: []))
    end

    let(:call_index) { 1 }
    subject { ChildSupport::ChildrenDisengagementService.new(group.id, call_index).call }

    context 'when processing call 1' do
      it 'disengages children with consecutive KO statuses' do
        expect { subject }.to change { disengaged_child.reload.group_status }.from('active').to('disengaged')
      end

      it 'disengages all siblings in the group' do
        subject
        expect(first_disengaged_child_in_siblings.reload.group_status).to eq 'disengaged'
        expect(second_disengaged_child_in_siblings.reload.group_status).to eq 'disengaged'
      end

      it 'does not disengage children with successful calls' do
        subject
        expect(child_to_conserve.reload.group_status).to eq 'active'
      end

      it "adds the 'desengage-2appelsKO' tag to the child support record" do
        subject
        expect(siblings_child_support.reload.tag_list).to include('desengage-2appelsKO')
      end
    end

    context 'when disengagement is manually avoided' do
      before do
        disengaged_child_support.update!(call1_avoid_disengagement_date: Time.zone.today)
      end

      it 'does not disengage the child even if statuses are KO' do
        subject
        expect(disengaged_child.reload.group_status).to eq 'active'
      end
    end

    context 'when the group does not have calls' do
      it 'does nothing' do
        group.update(type_of_support: 'without_calls')
        service = ChildSupport::ChildrenDisengagementService.new(group.id, 1)
        expect(ProgramMessageService).not_to receive(:new)
        expect(disengaged_child.reload.group_status).to eq 'active'
        service.call
      end
    end
  end

  describe "annonce d'arrêt lue dans ses trios" do
    def campaigns
      WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                              .select { |signature| signature.uri.path.start_with?('/api/envoyer/') }
                              .map { |signature| URI.decode_www_form(signature.body).to_h.merge('raw' => signature.body) }
    end

    def scheduled_at(campaign)
      campaign['date'].match?(/\A\d+\z/) ? Time.zone.at(campaign['date'].to_i) : Time.zone.parse(campaign['date'])
    end

    def announcement_bundle(name:, key:, body:)
      FactoryBot.create(:media_text_messages_bundle, name: name, body1: body, body2: nil, body3: nil).tap { |bundle| bundle.update_column(:key, key) }
    end

    def lucas_in_march_group
      group = FactoryBot.create(:group, name: 'Mars', type_of_support: 'with_calls', started_at: Time.zone.parse('2027-01-04'))
      lucas = FactoryBot.create(:child, first_name: 'Lucas', group: group, group_status: 'active', birthdate: 1.year.ago)
      [group, lucas]
    end

    def fail_first_two_calls(child)
      @marie ||= FactoryBot.create(:admin_user, user_role: 'caller', name: 'Marie')
      child.child_support.reload.update!(supporter: @marie, call0_status: 'KO', call1_status: 'KO')
      WebMock::RequestRegistry.instance.reset!
    end

    around { |example| travel_to(Time.zone.parse('2027-03-02 10:00')) { example.run } }

    [
      { situation: "Lucas n'a ni frère ni sœur", emma: nil, expected_status: nil, text: :single },
      { situation: 'Emma, sœur de Lucas, active dans « Mars »', emma: { group_status: 'active' }, expected_status: 'disengaged', text: :siblings },
      { situation: 'Emma, sœur de Lucas, arrêtée le mois dernier', emma: { group_status: 'stopped', group_end: 1.month.ago }, expected_status: 'stopped', text: :single },
      { situation: 'Emma, sœur de Lucas, en pause dans « Mars »', emma: { group_status: 'paused' }, expected_status: 'disengaged', text: :siblings },
      { situation: 'Emma, sœur de Lucas, en attente sans cohorte', emma: { group_status: 'waiting', group: nil }, expected_status: 'disengaged', text: :single }
    ].each do |example|
      it "envoie à 13 h le texte du trio #{example[:text] == :siblings ? 'fratrie' : 'pour un enfant'} quand #{example[:situation]}" do
        announcement_bundle(name: "Annonce d'arrêt (2 KO)", key: 'annonce_arret_deux_ko', body: 'On vous souhaite de beaux moments avec {PRENOM_ENFANT} !')
        announcement_bundle(name: "Annonce d'arrêt (2 KO) — fratrie", key: 'annonce_arret_deux_ko_fratrie', body: 'On vous souhaite de beaux moments avec vos enfants !')
        group, lucas = lucas_in_march_group
        emma = FactoryBot.create(:child, first_name: 'Emma', parent1: lucas.parent1, group: group, birthdate: 2.years.ago, **example[:emma]) if example[:emma]
        fail_first_two_calls(lucas)

        service = described_class.new(group.id, 1).call

        expect(service.errors).to be_empty
        expect(emma.reload.group_status).to eq(example[:expected_status]) if emma
        expect(campaigns.size).to eq(1)
        campaign = campaigns.first
        if example[:text] == :siblings
          expect(campaign['fallback_message'] || campaign['message']).to eq('On vous souhaite de beaux moments avec vos enfants !')
        else
          expect(campaign['fallback_message'] || campaign['message']).to eq('On vous souhaite de beaux moments avec {PRENOM_ENFANT} !')
          expect(campaign['raw']).to include('Lucas')
        end
        expect(scheduled_at(campaign)).to eq(Time.zone.parse('2027-03-02 13:00'))
      end
    end

    it "désengage Lucas avec le tag, n'envoie rien et signale le nom et la clé quand le trio de l'annonce est introuvable" do
      group, lucas = lucas_in_march_group
      fail_first_two_calls(lucas)

      service = described_class.new(group.id, 1).call

      expect(lucas.reload.group_status).to eq('disengaged')
      expect(lucas.child_support.reload.tag_list).to include('desengage-2appelsKO')
      expect(campaigns).to be_empty
      expect(service.errors).to include(a_string_including("Annonce d'arrêt (2 KO)", 'annonce_arret_deux_ko'))
    end

    it "envoie l'annonce aux familles à un enfant et signale le nom et la clé quand seul le trio fratrie est introuvable" do
      announcement_bundle(name: "Annonce d'arrêt (2 KO)", key: 'annonce_arret_deux_ko', body: 'On vous souhaite de beaux moments avec {PRENOM_ENFANT} !')
      group, lucas = lucas_in_march_group
      hugo = FactoryBot.create(:child, first_name: 'Hugo', group: group, group_status: 'active', birthdate: 1.year.ago)
      ines = FactoryBot.create(:child, first_name: 'Inès', parent1: hugo.parent1, group: group, group_status: 'active', birthdate: 2.years.ago)
      fail_first_two_calls(hugo)
      fail_first_two_calls(lucas)

      service = described_class.new(group.id, 1).call

      expect(campaigns.size).to eq(1)
      expect(campaigns.first['fallback_message'] || campaigns.first['message']).to eq('On vous souhaite de beaux moments avec {PRENOM_ENFANT} !')
      recipients = CGI.unescape(campaigns.first['raw'])
      expect(recipients).to include(lucas.parent1.phone_number)
      expect(recipients).not_to include(hugo.parent1.phone_number)
      expect([lucas, hugo, ines].map { |child| child.reload.group_status }).to all(eq('disengaged'))
      expect(service.errors).to contain_exactly(a_string_including("Annonce d'arrêt (2 KO) — fratrie", 'annonce_arret_deux_ko_fratrie'))
    end

    it "ne désengage personne, n'envoie rien et ne signale aucun trio manquant pour une cohorte sans appels" do
      group = FactoryBot.create(:group, name: 'Avril', type_of_support: 'without_calls', started_at: Time.zone.parse('2027-01-04'))
      lucas = FactoryBot.create(:child, first_name: 'Lucas', group: group, group_status: 'active', birthdate: 1.year.ago)
      fail_first_two_calls(lucas)

      service = described_class.new(group.id, 1).call

      expect(lucas.reload.group_status).to eq('active')
      expect(campaigns).to be_empty
      expect(service.errors).to be_empty
    end
  end
end
