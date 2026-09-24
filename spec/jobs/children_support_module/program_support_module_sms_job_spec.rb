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
end
