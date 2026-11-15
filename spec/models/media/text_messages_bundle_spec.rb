# == Schema Information
#
# Table name: media
#
#  id                 :bigint           not null, primary key
#  body1              :text
#  body2              :text
#  body3              :text
#  discarded_at       :datetime
#  name               :string
#  rcs_cta_title1     :string
#  rcs_cta_title2     :string
#  rcs_cta_title3     :string
#  rcs_text_template1 :boolean          default(FALSE), not null
#  rcs_text_template2 :boolean          default(FALSE), not null
#  rcs_text_template3 :boolean          default(FALSE), not null
#  rcs_title1         :string(200)
#  rcs_title2         :string(200)
#  rcs_title3         :string(200)
#  theme              :string
#  type               :string
#  url                :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  airtable_id        :string
#  folder_id          :bigint
#  image1_id          :bigint
#  image2_id          :bigint
#  image3_id          :bigint
#  link1_id           :bigint
#  link2_id           :bigint
#  link3_id           :bigint
#  rcs_media1_id      :integer
#  rcs_media2_id      :integer
#  rcs_media3_id      :integer
#  spot_hit_id        :string
#
# Indexes
#
#  index_media_on_airtable_id   (airtable_id) UNIQUE
#  index_media_on_discarded_at  (discarded_at)
#  index_media_on_folder_id     (folder_id)
#  index_media_on_image1_id     (image1_id)
#  index_media_on_image2_id     (image2_id)
#  index_media_on_image3_id     (image3_id)
#  index_media_on_link1_id      (link1_id)
#  index_media_on_link2_id      (link2_id)
#  index_media_on_link3_id      (link3_id)
#  index_media_on_type          (type)
#
# Foreign Keys
#
#  fk_rails_...  (folder_id => media_folders.id)
#  fk_rails_...  (image1_id => media.id)
#  fk_rails_...  (image2_id => media.id)
#  fk_rails_...  (image3_id => media.id)
#  fk_rails_...  (link1_id => media.id)
#  fk_rails_...  (link2_id => media.id)
#  fk_rails_...  (link3_id => media.id)
#


require 'rails_helper'

RSpec.describe Media::TextMessagesBundle, type: :model do

  before(:each) do
    @text_messages_bundle = FactoryBot.build(
      :media_text_messages_bundle
    )
  end

  context 'is valid' do
    it 'if minimal attributes are present' do
      expect(@text_messages_bundle).to be_valid
    end
  end

  context 'is not valid' do
    it 'if no name is given' do
      @text_messages_bundle.name = nil
      expect(@text_messages_bundle).to_not be_valid
    end
    it 'if no body1 is given' do
      @text_messages_bundle.body1 = nil
      expect(@text_messages_bundle).to_not be_valid
    end
    it 'if no body2 is given but image2 is given' do
      image = FactoryBot.build(:media_image)
      @text_messages_bundle.body2 = nil
      @text_messages_bundle.image2 = image
      expect(@text_messages_bundle).to_not be_valid
    end
    it 'if no body3 is given but image3 is given' do
      image = FactoryBot.build(:media_image)
      @text_messages_bundle.body3 = nil
      @text_messages_bundle.image3 = image
      expect(@text_messages_bundle).to_not be_valid
    end
  end

  context 'sans type de modèle précisé' do
    it 'considère les trois modèles enregistrés comme des modèles carte' do
      bundle = Media::TextMessagesBundle.new

      expect([bundle.rcs_text_template1, bundle.rcs_text_template2, bundle.rcs_text_template3]).to eq([false, false, false])
    end
  end

  describe 'création du modèle Spot-Hit à l\'enregistrement' do
    def created_models
      WebMock::RequestRegistry.instance.requested_signatures.hash.keys
        .select { |signature| signature.uri.path == '/api/rcs/model/create' }
        .map { |signature| JSON.parse(Rack::Utils.parse_nested_query(signature.body)['model']) }
    end

    [120, 300].each do |bytesize|
      it "crée un modèle texte pour un nouveau message sans image de #{bytesize} octets et l'enregistre" do
        stub_request(:post, SpotHit::CreateRcsModelService::URL)
          .to_return(status: 200, body: { success: true, id: 4521 }.to_json)
        bundle = FactoryBot.create(:media_text_messages_bundle, body1: 'Bonjour !', body2: nil, body3: nil)
        body2 = "Chantez une comptine. #{'a' * (bytesize - 22)}"

        bundle.update!(body2: body2)

        model = created_models.find { |m| m.dig('content', 'text', 'text')&.start_with?('Chantez une comptine') }
        expect(model['type']).to eq('text')
        expect(bundle.reload).to have_attributes(rcs_media2_id: 4521, rcs_text_template2: true)
      end
    end

    it 'retire le préfixe « 1001mots : » du texte du modèle sans toucher au texte du trio' do
      body = "1001mots : cette semaine, chantez une comptine avec {PRENOM_ENFANT} pendant le bain. #{'a' * 120}"

      bundle = FactoryBot.create(:media_text_messages_bundle, body1: body, body2: nil, body3: nil)

      expect(created_models.last.dig('content', 'text', 'text')).to start_with('Cette semaine, chantez une comptine')
      expect(bundle.reload.body1).to eq(body)
    end

    it 'garde le lien dans le texte du modèle texte, sans bouton' do
      video = FactoryBot.create(:media_video, name: 'Comptine du bain')

      FactoryBot.create(:media_text_messages_bundle, body1: "Découvrez\nla comptine de la semaine.", link1: video, body2: nil, body3: nil)

      expect(created_models.last).to eq(
        'type' => 'text',
        'content' => {
          'text' => { 'text' => 'Découvrez<br>la comptine de la semaine. {URL}', 'suggestions' => [] },
          'property' => { 'stop' => false }
        }
      )
    end
  end

  describe '#sync_rcs_models' do
    let(:image) { FactoryBot.create(:media_image) }
    let!(:bundle) do
      text_messages = FactoryBot.create(:media_text_messages_bundle, body2: nil, body3: nil)
      text_messages.update_columns(rcs_media1_id: 123, image1_id: image.id)
      text_messages.reload
    end

    context 'when rcs_media_id is present and image_id is nil' do
      it 'enqueues DeleteRcsModelJob with the rcs_media_id' do
        allow(SpotHit::DeleteRcsModelJob).to receive(:set).and_return(SpotHit::DeleteRcsModelJob)
        expect(SpotHit::DeleteRcsModelJob).to receive(:perform_later).with(123)
        bundle.update!(image1_id: nil)
      end

      it 'sets rcs_media1_id to nil in the database' do
        allow(SpotHit::DeleteRcsModelJob).to receive(:set).and_return(SpotHit::DeleteRcsModelJob)
        bundle.update!(image1_id: nil)
        expect(bundle.reload.rcs_media1_id).to be_nil
      end
    end

    context 'when rcs_media_id is present and image changed' do
      let(:bundle) do
        text_messages = FactoryBot.create(:media_text_messages_bundle, body2: nil, body3: nil)
        text_messages.update_columns(rcs_media1_id: 456, image1_id: image.id)
        text_messages.reload
      end

      let(:service_result) { double('service_result', errors: []) }
      let(:service_instance) { double('service_instance', call: service_result) }

      it 'calls UpdateRcsModelService when body changes' do
        expect(SpotHit::UpdateRcsModelService).to receive(:new)
          .with(text_messages_bundle: bundle, message_index: 1)
          .and_return(service_instance)
        bundle.update!(body1: 'new body')
      end

      it 'calls UpdateRcsModelService when rcs_title changes' do
        expect(SpotHit::UpdateRcsModelService).to receive(:new)
          .with(text_messages_bundle: bundle, message_index: 1)
          .and_return(service_instance)
        bundle.update!(rcs_title1: 'new title')
      end

      it 'calls UpdateRcsModelService when image changes' do
        new_image = FactoryBot.create(:media_image)
        expect(SpotHit::UpdateRcsModelService).to receive(:new)
          .with(text_messages_bundle: bundle, message_index: 1)
          .and_return(service_instance)
        bundle.update!(image1_id: new_image.id)
      end

      it 'reports to Rollbar when UpdateRcsModelService has errors' do
        error_result = double('error_result', errors: ['SpotHit error'])
        error_instance = double('error_instance', call: error_result)
        allow(SpotHit::UpdateRcsModelService).to receive(:new).and_return(error_instance)
        expect(Rollbar).to receive(:error).with('SpotHit::UpdateRcsModelService', anything)
        bundle.update!(body1: 'new body')
      end
    end

    context 'when rcs_media_id is nil and image_id is present' do
      let(:bundle) do
        text_messages = FactoryBot.create(:media_text_messages_bundle, body2: nil, body3: nil)
        text_messages.update_columns(rcs_media1_id: nil)
        text_messages.reload
      end

      it 'calls CreateRcsModelService when image is added' do
        service_result = double('service_result', errors: [])
        service_instance = double('service_instance', call: service_result)
        expect(SpotHit::CreateRcsModelService).to receive(:new)
          .with(text_messages_bundle: bundle, message_index: 1)
          .and_return(service_instance)
        bundle.update!(image1_id: image.id)
      end

      it 'reports to Rollbar when CreateRcsModelService has errors' do
        error_result = double('error_result', errors: ['SpotHit error'])
        error_instance = double('error_instance', call: error_result)
        allow(SpotHit::CreateRcsModelService).to receive(:new).and_return(error_instance)
        expect(Rollbar).to receive(:error).with('SpotHit::CreateRcsModelService', anything)
        bundle.update!(image1_id: image.id)
      end
    end
  end
end
