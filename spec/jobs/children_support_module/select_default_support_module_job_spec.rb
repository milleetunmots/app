require 'rails_helper'

RSpec.describe ChildrenSupportModule::SelectDefaultSupportModuleJob do
  # ChildSupport#current_child écarte les enfants archivés : une fiche dont tous
  # les enfants sont archivés n'a plus de current_child. Un enfant archivé peut
  # pourtant rester `active` dans sa cohorte.
  describe 'fiche sans enfant non archivé' do
    let!(:group) { FactoryBot.create(:group) }
    let!(:child) { FactoryBot.create(:child, group: group, group_status: 'active') }

    before { child.discard! }

    it 'ne plante pas en listant les enfants courants de la cohorte' do
      expect(child.reload.child_support.current_child).to be_nil
      expect(described_class.new.send(:active_current_children_with_child_support, group)).to eq []
    end
  end
end
