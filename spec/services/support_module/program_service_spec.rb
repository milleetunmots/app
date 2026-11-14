require 'rails_helper'

RSpec.describe SupportModule::ProgramService do
  describe '#call' do
    context 'quand un message sans image a déjà un modèle RCS' do
      it "ne crée aucun nouveau modèle chez Spot-Hit et garde l'identifiant existant" do
        stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
          .to_return(status: 200, body: { success: true, campaign_id: '123' }.to_json)
        stub_request(:post, SpotHit::CreateRcsModelService::URL)
          .to_return(status: 200, body: { success: true, id: 9999 }.to_json)
        group = FactoryBot.create(:group)
        child = FactoryBot.create(:child, first_name: 'Léa', group: group, group_status: 'active')
        bundle = FactoryBot.create(:media_text_messages_bundle, body1: 'Bonjour !', body2: 'Chantez une comptine ce soir.', body3: nil)
        bundle.update_column(:rcs_media2_id, 4521)
        support_module = FactoryBot.create(:support_module)
        FactoryBot.create(:support_module_week, support_module: support_module, medium: bundle)

        service = SupportModule::ProgramService.new(
          support_module,
          Time.zone.today.next_occurring(:monday),
          recipients: ["parent.#{child.parent1_id}"]
        ).call

        expect(service.errors).to be_empty
        expect(WebMock).not_to have_requested(:post, SpotHit::CreateRcsModelService::URL)
        expect(bundle.reload.rcs_media2_id).to eq(4521)
      end
    end
  end
end
