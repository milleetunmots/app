require "rails_helper"

RSpec.describe ProgramMessagesHelper, type: :helper do
  describe "#retrieve_messages" do
    let(:support_module) { FactoryBot.create(:support_module) }
    let(:main_image) { FactoryBot.create(:media_image) }
    let(:additional_image) { FactoryBot.create(:media_image) }
    let(:main_bundle) { FactoryBot.create(:media_text_messages_bundle) }
    let(:additional_bundle) { FactoryBot.create(:media_text_messages_bundle) }

    before do
      # update_columns pour ne pas déclencher la synchronisation des modèles RCS avec Spot Hit
      main_bundle.update_columns(image1_id: main_image.id, rcs_media1_id: 111)
      additional_bundle.update_columns(image1_id: additional_image.id, rcs_media1_id: 444)
      FactoryBot.create(:support_module_week, support_module: support_module, medium: main_bundle, additional_medium: additional_bundle)
    end

    it "builds the 4th message from the additional medium" do
      message4 = helper.retrieve_messages(support_module.id)["support_module_week_1"][:message_4]

      expect(message4[:body]).to eq additional_bundle.body1
      expect(message4[:file]).to eq additional_image
      expect(message4[:rcs_media]).to eq 444
    end
  end
end
