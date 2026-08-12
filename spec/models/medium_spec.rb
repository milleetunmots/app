# == Schema Information
#
# Table name: media
#
#  id             :bigint           not null, primary key
#  body1          :text
#  body2          :text
#  body3          :text
#  discarded_at   :datetime
#  name           :string
#  rcs_cta_title1 :string
#  rcs_cta_title2 :string
#  rcs_cta_title3 :string
#  rcs_title1     :string(200)
#  rcs_title2     :string(200)
#  rcs_title3     :string(200)
#  theme          :string
#  type           :string
#  url            :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  airtable_id    :string
#  folder_id      :bigint
#  image1_id      :bigint
#  image2_id      :bigint
#  image3_id      :bigint
#  link1_id       :bigint
#  link2_id       :bigint
#  link3_id       :bigint
#  rcs_media1_id  :integer
#  rcs_media2_id  :integer
#  rcs_media3_id  :integer
#  spot_hit_id    :string
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

RSpec.describe Medium, type: :model do
  before(:each) do
    stub_request(:post, 'https://www.spot-hit.fr/api/mms/upload').
      to_return(status: 200, body: '{"success":true, "file":"1234.png"}')

    @with_folder = FactoryBot.create(:medium, folder: FactoryBot.create(:media_folder))
    @document = FactoryBot.create(:media_document)
    @form = FactoryBot.create(:media_form)
    @image = FactoryBot.create(:media_image)
    @video = FactoryBot.create(:media_video)
    @text_message_bundle = FactoryBot.create(:media_text_messages_bundle)
    @text_messages_bundle_draft = FactoryBot.create(:media_text_messages_bundle_draft)
  end

  describe 'Validations' do
    context 'succeed' do
      it 'if the medium has a name' do
        expect(FactoryBot.build_stubbed(:medium)).to be_valid
      end
    end

    context 'fail' do
      it "if the medium doesn't have a name" do
        expect(FactoryBot.build_stubbed(:medium, name: nil)).not_to be_valid
      end
    end
  end

  describe '#without_folder' do
    context 'returns' do
      it 'mediums without folder' do
        expect(Medium.without_folder).not_to include @with_folder
        expect(Medium.without_folder).to match_array [@document, @form, @image, @video, @text_message_bundle, @text_messages_bundle_draft]
      end
    end
  end

  describe '#docmuents' do
    context 'returns' do
      it 'documents' do
        expect(Medium.documents).to match_array [@document]
        expect(Medium.documents).not_to include @form, @image, @video, @text_message_bundle, @text_messages_bundle_draft
      end
    end
  end

  describe '#forms' do
    context 'returns' do
      it 'forms' do
        expect(Medium.forms).to match_array [@form]
        expect(Medium.forms).not_to include @document, @image, @video, @text_message_bundle, @text_messages_bundle_draft
      end
    end
  end

  describe '#images' do
    context 'returns' do
      it 'images' do
        expect(Medium.images).to match_array [@image]
        expect(Medium.images).not_to include @document, @form, @video, @text_message_bundle, @text_messages_bundle_draft
      end
    end
  end

  describe '#videos' do
    context 'returns' do
      it 'videos' do
        expect(Medium.videos).to match_array [@video]
        expect(Medium.videos).not_to include @document, @image, @form, @text_message_bundle, @text_messages_bundle_draft
      end
    end
  end

  describe '#text_messages_bundles' do
    context 'returns' do
      it 'text messages bundles' do
        expect(Medium.text_messages_bundles).to match_array [@text_message_bundle]
        expect(Medium.text_messages_bundles).not_to include @document, @image, @video, @form, @text_messages_bundle_draft
      end
    end
  end

  describe '#text_messages_bundle_drafts' do
    context 'returns' do
      it 'text messages bundle drafts' do
        expect(Medium.text_messages_bundle_drafts).to match_array [@text_messages_bundle_draft]
        expect(Medium.text_messages_bundle_drafts).not_to include @document, @image, @video, @text_message_bundle, @form
      end
    end
  end

  describe '#for_redirections' do
    context 'returns' do
      it 'forms and videos' do
        expect(Medium.for_redirections).to match_array [@form, @video]
        expect(Medium.for_redirections).not_to include @document, @image, @text_message_bundle, @text_messages_bundle_draft
      end
    end
  end

  describe "validation de l'url contre AllowedPattern (types utilisables en redirection)" do
    context 'avec URL_FILTER_BLOCKING_ENABLED' do
      # before/after plutôt que around : le before(:each) global crée des médias
      # avec des urls Faker qui ne doivent pas subir la validation.
      before { ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true' }
      after { ENV.delete('URL_FILTER_BLOCKING_ENABLED') }

      it "refuse un Media::Video dont l'url n'est pas whitelistée" do
        video = FactoryBot.build(:media_video, url: 'https://non-whitelisted.example.com/video')

        expect(video).not_to be_valid
        expect(video.errors[:url]).to be_present
      end

      it "refuse un Media::Form dont l'url n'est pas whitelistée" do
        form = FactoryBot.build(:media_form, url: 'https://non-whitelisted.example.com/form')

        expect(form).not_to be_valid
      end

      it 'accepte un Media::Video dont le domaine est whitelisté' do
        FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'partenaire.fr')
        video = FactoryBot.build(:media_video, url: 'https://partenaire.fr/video')

        expect(video).to be_valid
      end

      it 'ne bloque pas un média existant tant que son url ne change pas' do
        expect(@video.update(name: 'Nouveau nom')).to be(true)
      end

      it 'ne contrôle pas les types non utilisables en redirection (Media::Document)' do
        document = FactoryBot.build(:media_document, url: 'https://non-whitelisted.example.com/doc')

        expect(document).to be_valid
      end
    end

    context 'sans URL_FILTER_BLOCKING_ENABLED (mode surveillance)' do
      it 'accepte une url non whitelistée mais la signale' do
        video = FactoryBot.build(:media_video, url: 'https://non-whitelisted.example.com/video')

        expect(Rollbar).to receive(:warning).with('Medium : url qui serait refusée par le filtre', hash_including(url: 'https://non-whitelisted.example.com/video'))
        expect(video).to be_valid
      end

      it 'ne signale rien pour une url whitelistée' do
        FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'partenaire.fr')
        video = FactoryBot.build(:media_video, url: 'https://partenaire.fr/video')

        expect(Rollbar).not_to receive(:warning)
        expect(video).to be_valid
      end
    end
  end
end
