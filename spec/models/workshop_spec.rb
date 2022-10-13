# == Schema Information
#
# Table name: workshops
#
#  id                 :bigint           not null, primary key
#  address            :string           not null
#  city_name          :string           not null
#  co_animator        :string
#  discarded_at       :datetime
#  invitation_message :text             not null
#  name               :string
#  postal_code        :string           not null
#  topic              :string           not null
#  workshop_date      :date             not null
#  workshop_land      :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  animator_id        :bigint           not null
#
# Indexes
#
#  index_workshops_on_animator_id  (animator_id)
#
# Foreign Keys
#
#  fk_rails_...  (animator_id => admin_users.id)
#
require "rails_helper"

RSpec.describe Workshop, type: :model do
  describe "Validations" do
    context "succeed" do
      it "if minimal attributes are present" do
        expect(FactoryBot.build_stubbed(:workshop)).to be_valid
      end
    end

    context "fail" do
      it "if topic is not given" do
        expect(FactoryBot.build_stubbed(:workshop, topic: nil)).not_to be_valid
      end

      it "if animator is not given" do
        expect(FactoryBot.build_stubbed(:workshop, animator: nil)).not_to be_valid
      end

      it "if workshop_date is not given" do
        expect(FactoryBot.build_stubbed(:workshop, workshop_date: nil)).not_to be_valid
      end

      it "if address is not given" do
        expect(FactoryBot.build_stubbed(:workshop, address: nil)).not_to be_valid
      end

      it "if postal_code is not given" do
        expect(FactoryBot.build_stubbed(:workshop, postal_code: nil)).not_to be_valid
      end

      it "if city_name is not given" do
        expect(FactoryBot.build_stubbed(:workshop, city_name: nil)).not_to be_valid
      end

      it "if invitation_message is not given" do
        expect(FactoryBot.build_stubbed(:workshop, invitation_message: nil)).not_to be_valid
      end
    end
  end

  describe ".name" do
    context "format" do
      let(:workshop) { FactoryBot.create(:workshop, workshop_date: Date.today.next_day) }
      let(:paris_18_workshop) { FactoryBot.create(:workshop, workshop_date: Date.today.next_day(2), workshop_land: "Paris 18 eme") }

      it "is 'Atelier_year_month' if land is not given" do
        expect(workshop.name).to eq "Atelier du #{Date.today.next_day.month}/#{Date.today.next_day.year}"
      end
      it "if land is given is 'Atelier_land_year_month'" do
        expect(paris_18_workshop.name).to eq "Atelier du #{Date.today.next_day.month}/#{Date.today.next_day.year} à @Paris 18 eme"
      end
    end
  end
end
