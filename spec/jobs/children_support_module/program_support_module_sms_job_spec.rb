require 'rails_helper'

RSpec.describe ChildrenSupportModule::ProgramSupportModuleSmsJob do
  # Le job partitionne les enfants actifs d'une cohorte en « courants » (qui
  # reçoivent le SMS) et « non courants » (dont les CSM sont simplement marqués
  # is_programmed: true). Avec deux tris concurrents non départagés, un jumeau
  # pouvait être courant pour la fiche de suivi et non courant pour le job :
  # ses CSM passaient alors programmés sans module ni livre.
  describe 'partition current / not current avec des jumeaux' do
    let!(:group) { FactoryBot.create(:group) }
    let!(:parent1) { FactoryBot.create(:parent) }
    let(:birthdate) { 8.months.ago.to_date }

    let!(:twin_a) do
      FactoryBot.create(:child, parent1: parent1, group: group, group_status: 'active', birthdate: birthdate)
    end
    let!(:twin_b) do
      FactoryBot.create(:child, parent1: parent1, group: group, group_status: 'active', birthdate: birthdate)
    end

    let(:child_support) { twin_a.reload.child_support }
    let(:job) { described_class.new.tap { |j| j.instance_variable_set(:@group, group) } }

    it 'ne classe jamais le current_child de la fiche parmi les not_current_children' do
      expect(job.send(:not_current_children)).not_to include(child_support.current_child)
    end

    it 'désigne comme courant le même enfant que la fiche de suivi' do
      expect(job.send(:current_children)).to eq [child_support.current_child]
    end

    it 'partitionne les enfants actifs sans doublon ni perte' do
      expect(job.send(:current_children) + job.send(:not_current_children))
        .to match_array(group.children.where(group_status: 'active'))
    end

    # Un enfant archivé ne doit jamais être désigné courant (il ne recevrait
    # aucun SMS), mais il reste dans not_current_children pour que ses CSM
    # soient bien marqués programmés et ne ressortent pas dans l'export suivant.
    it "ne désigne jamais un enfant archivé comme courant" do
      [twin_a, twin_b].max_by(&:id).discard

      expect(job.send(:current_children)).to eq [[twin_a, twin_b].min_by(&:id)]
      expect(job.send(:not_current_children)).to eq [[twin_a, twin_b].max_by(&:id)]
    end

    it "désigne le jumeau restant quand le premier inscrit est archivé" do
      [twin_a, twin_b].min_by(&:id).discard

      expect(job.send(:current_children)).to eq [[twin_a, twin_b].max_by(&:id)]
    end
  end

  # Le Module 1 (compteur à 1) n'est jamais vu par le job d'export logistique : l'attribution enregistre
  # son livre. À partir du module d'index 3 (compteur à 2), c'est l'export qui l'enregistre.
  describe '#perform' do
    let!(:group) { FactoryBot.create(:group) }
    let!(:book) { FactoryBot.create(:book) }
    let!(:support_module) { FactoryBot.create(:support_module, book: book) }
    let!(:child) { FactoryBot.create(:child, group: group, group_status: 'active') }
    let!(:children_support_module) do
      FactoryBot.create(:children_support_module, child: child, parent: child.parent1, support_module: support_module)
    end
    # la programmation réelle appelle Spot-Hit et attend 60 s par module
    let(:program_service) { instance_double(ChildSupport::ProgramChosenModulesService, errors: []) }

    before do
      allow(ChildSupport::ProgramChosenModulesService).to receive(:new).and_return(program_service)
      allow(program_service).to receive(:call).and_return(program_service)
      allow(Rollbar).to receive(:error)
    end

    def perform_with(support_module_programmed)
      group.update_column(:support_module_programmed, support_module_programmed)
      described_class.perform_now(group.id, Date.new(2026, 11, 9))
    end

    context 'pour le module 1' do
      it 'enregistre le livre' do
        perform_with(1)

        expect(children_support_module.reload[:book_id]).to eq(book.id)
      end
    end

    context 'pour le module 0' do
      it "n'enregistre pas de livre" do
        perform_with(0)

        expect(children_support_module.reload[:book_id]).to be_nil
      end
    end

    context "pour un module d'index 3 et plus" do
      context "quand l'export logistique n'a pas enregistré le livre" do
        it "n'enregistre pas le livre" do
          perform_with(2)

          expect(children_support_module.reload[:book_id]).to be_nil
        end

        it 'alerte Rollbar avec la cohorte et le module' do
          perform_with(2)

          expect(Rollbar).to have_received(:error).with(
            'ChildrenSupportModule::ProgramSupportModuleSmsJob',
            errors: [hash_including(context: { group_id: group.id, children_support_module_ids: [children_support_module.id] })]
          )
        end

        it 'programme quand même les SMS du module' do
          perform_with(2)

          expect(program_service).to have_received(:call)
        end
      end

      context "quand l'export logistique a enregistré le livre" do
        before { children_support_module.update_column(:book_id, book.id) }

        it "n'alerte pas Rollbar" do
          perform_with(2)

          expect(Rollbar).not_to have_received(:error)
        end
      end
    end
  end

  # Sans fiche de suivi, pas de fratrie connue : l'enfant doit rester courant,
  # sinon ses CSM passeraient programmés sans qu'aucun SMS ne parte.
  describe 'enfant actif sans fiche de suivi' do
    let!(:group) { FactoryBot.create(:group) }
    let!(:lonely_child) { FactoryBot.create(:child, group: group, group_status: 'active') }
    let!(:other_lonely_child) { FactoryBot.create(:child, group: group, group_status: 'active') }
    let(:job) { described_class.new.tap { |j| j.instance_variable_set(:@group, group) } }

    before do
      lonely_child.update_column(:child_support_id, nil)
      other_lonely_child.update_column(:child_support_id, nil)
    end

    it 'le désigne comme courant, chacun pour soi' do
      expect(job.send(:current_children)).to contain_exactly(lonely_child, other_lonely_child)
      expect(job.send(:not_current_children)).to be_empty
    end
  end
end
