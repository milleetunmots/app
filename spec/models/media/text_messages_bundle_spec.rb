# == Schema Information
#
# Table name: media
#
#  id                 :bigint           not null, primary key
#  body1              :text
#  body2              :text
#  body3              :text
#  discarded_at       :datetime
#  key                :string
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
#  index_media_on_key           (key) UNIQUE WHERE (key IS NOT NULL)
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

  describe '#changed_rcs_message_indexes' do
    it "donne les messages dont le texte, l'image, le titre, le lien ou le bouton viennent de changer" do
      bundle = FactoryBot.create(:media_text_messages_bundle, body1: 'Bonjour !', body2: 'À demain !', body3: 'Chantez !')

      bundle.update!(body2: 'À ce soir !', rcs_title3: 'Nouveau titre')

      expect(bundle.changed_rcs_message_indexes).to eq([2, 3])
    end
  end

  describe '.missing_message' do
    it 'nomme le trio et sa clé' do
      expect(described_class.missing_message(name: 'Fin du programme', key: 'fin_programme'))
        .to eq('Trio introuvable : « Fin du programme » (clé fin_programme), message non envoyé')
    end
  end

  describe '#redirection_target_id' do
    it 'renvoie la cible de redirection du lien du message, la même à chaque appel' do
      video = FactoryBot.create(:media_video)
      bundle = FactoryBot.create(:media_text_messages_bundle, link2: video)

      expect(bundle.redirection_target_id(2)).to eq(RedirectionTarget.find_by(medium_id: video.id).id)
      expect(bundle.redirection_target_id(2)).to eq(bundle.redirection_target_id(2))
    end

    it "ne renvoie rien quand le message n'a pas de lien" do
      bundle = FactoryBot.create(:media_text_messages_bundle, link1: nil)

      expect(bundle.redirection_target_id(1)).to be_nil
    end
  end
end
