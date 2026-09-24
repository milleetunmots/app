# == Schema Information
#
# Table name: support_modules
#
#  id                  :bigint           not null, primary key
#  age_ranges          :string           is an Array
#  discarded_at        :datetime
#  for_bilingual       :boolean          default(FALSE), not null
#  level               :integer
#  name                :string
#  start_at            :date
#  theme               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  airtable_content_id :string
#  airtable_id         :string
#  book_id             :bigint
#
# Indexes
#
#  index_support_modules_on_age_ranges    (age_ranges) USING gin
#  index_support_modules_on_airtable_id   (airtable_id) UNIQUE
#  index_support_modules_on_book_id       (book_id)
#  index_support_modules_on_discarded_at  (discarded_at)
#
# Foreign Keys
#
#  fk_rails_...  (book_id => books.id)
#

require "rails_helper"

RSpec.describe SupportModule, type: :model do
  describe "Validations" do
    context "succeed" do
      it "if minimal attributes are present" do
        expect(FactoryBot.build(:support_module)).to be_valid
      end
    end

    context "fail" do
      it "if the support module doesn't have name" do
        expect(FactoryBot.build(:support_module, name: nil)).not_to be_valid
      end
    end
  end

  describe ".age_range_for" do
    it "maps each granular range" do
      expect(SupportModule.age_range_for(4)).to eq SupportModule::FOUR_TO_ELEVEN
      expect(SupportModule.age_range_for(11)).to eq SupportModule::FOUR_TO_ELEVEN
      expect(SupportModule.age_range_for(12)).to eq SupportModule::TWELVE_TO_SEVENTEEN
      expect(SupportModule.age_range_for(17)).to eq SupportModule::TWELVE_TO_SEVENTEEN
      expect(SupportModule.age_range_for(18)).to eq SupportModule::EIGHTEEN_TO_TWENTY_THREE
      expect(SupportModule.age_range_for(23)).to eq SupportModule::EIGHTEEN_TO_TWENTY_THREE
      expect(SupportModule.age_range_for(24)).to eq SupportModule::TWENTY_FOUR_TO_TWENTY_NINE
      expect(SupportModule.age_range_for(29)).to eq SupportModule::TWENTY_FOUR_TO_TWENTY_NINE
    end

    # Pas de plafond ici : les appelants qui cherchent des modules adaptés à
    # l'âge ont besoin de la vraie tranche. Le repli sur une tranche plus basse
    # quand aucun module par défaut n'existe est la politique de
    # SelectDefaultSupportModuleService, pas celle du référentiel.
    it "maps the ranges above thirty months without capping them" do
      expect(SupportModule.age_range_for(30)).to eq SupportModule::THIRTY_TO_THIRTY_FIVE
      expect(SupportModule.age_range_for(35)).to eq SupportModule::THIRTY_TO_THIRTY_FIVE
      expect(SupportModule.age_range_for(36)).to eq SupportModule::THIRTY_SIX_TO_FORTY
      expect(SupportModule.age_range_for(40)).to eq SupportModule::THIRTY_SIX_TO_FORTY
      expect(SupportModule.age_range_for(41)).to eq SupportModule::FORTY_ONE_TO_FORTY_FOUR
      expect(SupportModule.age_range_for(44)).to eq SupportModule::FORTY_ONE_TO_FORTY_FOUR
    end

    it "returns a blank range outside the referential" do
      expect(SupportModule.age_range_for(3)).to eq ''
      expect(SupportModule.age_range_for(0)).to eq ''
      expect(SupportModule.age_range_for(nil)).to eq ''
      expect(SupportModule.age_range_for(45)).to eq ''
      expect(SupportModule.age_range_for(120)).to eq ''
    end
  end

  describe ".age_range_for_capped" do
    it "leaves the ages covered by the referential untouched" do
      expect(SupportModule.age_range_for_capped(4)).to eq SupportModule::FOUR_TO_ELEVEN
      expect(SupportModule.age_range_for_capped(30)).to eq SupportModule::THIRTY_TO_THIRTY_FIVE
      expect(SupportModule.age_range_for_capped(44)).to eq SupportModule::FORTY_ONE_TO_FORTY_FOUR
    end

    # Un enfant inscrit à 30 mois dépasse 44 mois avant la fin de ses deux ans
    # d'accompagnement : il doit recevoir la dernière tranche, pas aucune.
    it "attaches ages beyond the referential to its last range" do
      expect(SupportModule.age_range_for_capped(45)).to eq SupportModule::FORTY_ONE_TO_FORTY_FOUR
      expect(SupportModule.age_range_for_capped(120)).to eq SupportModule::FORTY_ONE_TO_FORTY_FOUR
    end

    it "honours a lower cap" do
      expect(SupportModule.age_range_for_capped(120, cap: 35)).to eq SupportModule::THIRTY_TO_THIRTY_FIVE
      expect(SupportModule.age_range_for_capped(38, cap: 35)).to eq SupportModule::THIRTY_TO_THIRTY_FIVE
    end

    # Le plancher n'est pas plafonné : en dessous de 4 mois il n'y a rien à
    # proposer, et rattacher ces enfants à la première tranche serait un choix
    # de contenu, pas un garde-fou.
    it "keeps a blank range below the referential" do
      expect(SupportModule.age_range_for_capped(3)).to eq ''
      expect(SupportModule.age_range_for_capped(0)).to eq ''
      expect(SupportModule.age_range_for_capped(nil)).to eq ''
    end
  end

  describe ".duplicate" do
    context "returns" do
      it "new support module with the same attributes" do
        support_module = FactoryBot.create(:support_module)
        new_support_module = support_module.duplicate
        expect(new_support_module.name).to eq "Copie de #{support_module.name}"
        expect(new_support_module.tag_list).to eq support_module.tag_list
        expect(new_support_module.support_module_weeks).to eq support_module.support_module_weeks
      end
    end
  end
end
