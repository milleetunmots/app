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
#  location           :string
#  name               :string
#  postal_code        :string           not null
#  topic              :string
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
      it "if animator is not given" do
        expect(FactoryBot.build_stubbed(:workshop, animator: nil)).not_to be_valid
      end

      it "if workshop_date is not given" do
        expect(FactoryBot.build_stubbed(:workshop, workshop_date: nil)).not_to be_valid
      end

      it "if workshop_date has already passed" do
        expect(FactoryBot.build(:workshop, workshop_date: Date.today.prev_day(3))).not_to be_valid
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

      it "if workshop_land is not included in children's lands" do
        expect(FactoryBot.build_stubbed(:workshop, workshop_land: "New York")).not_to be_valid
      end
    end
  end

  describe ".name" do
    context "format" do
      let(:animator) { FactoryBot.create(:admin_user, name: "Angela") }
      let(:workshop) { FactoryBot.create(:workshop, animator: animator, workshop_date: Date.today.next_day) }
      let(:meal_workshop) { FactoryBot.create(:workshop, animator: animator, workshop_date: Date.today.next_day(4), location: "Merlun", topic: "meal") }
      let(:paris_workshop) { FactoryBot.create(:workshop, animator: animator, workshop_date: Date.today.next_day(2), location: "Paris") }

      it "is 'Atelier du workshop_date à location, avec animator, sur le thème topic'" do
        expect(workshop.name).to eq "Atelier du #{Date.today.next_day.day}/#{Date.today.next_day.month}/#{Date.today.next_day.year}, avec Angela"
        expect(paris_workshop.name).to eq "Atelier du #{Date.today.next_day(2).day}/#{Date.today.next_day(2).month}/#{Date.today.next_day(2).year} à Paris, avec Angela"
        expect(meal_workshop.name).to eq "Atelier du #{Date.today.next_day(4).day}/#{Date.today.next_day(4).month}/#{Date.today.next_day(4).year} à Merlun, avec Angela, sur le thème \"Repas\""
      end
    end
  end

  # describe ".set_workshop_participation" do
  #   context "create workshop_participation for each parent invited" do
  #
  #   end
  # end
end
