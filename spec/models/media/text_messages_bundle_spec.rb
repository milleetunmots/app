# == Schema Information
#
# Table name: media
#
#  id           :bigint           not null, primary key
#  body1        :text
#  body2        :text
#  body3        :text
#  discarded_at :datetime
#  name         :string
#  rcs_title1    :string(200)
#  rcs_title2    :string(200)
#  rcs_title3    :string(200)
#  theme        :string
#  type         :string
#  url          :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  airtable_id  :string
#  folder_id    :bigint
#  image1_id    :bigint
#  image2_id    :bigint
#  image3_id    :bigint
#  link1_id     :bigint
#  link2_id     :bigint
#  link3_id     :bigint
#  rcs_media1_id :integer
#  rcs_media2_id :integer
#  rcs_media3_id :integer
#  spot_hit_id  :string
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
      let(:bundle) { FactoryBot.create(:media_text_messages_bundle, body2: nil, body3: nil) }

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
