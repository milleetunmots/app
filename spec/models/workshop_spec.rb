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
      it "if land is not given" do
        expect(FactoryBot.build_stubbed(:workshop, land: nil)).not_to be_valid
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
      let(:loiret_workshop) { FactoryBot.create(:workshop, workshop_date: Date.new(2022, 3, 5), land: "Loiret") }
      let(:paris_18_workshop) { FactoryBot.create(:workshop, workshop_date: Date.new(2022, 1, 5), land: "Paris", tag_list: %w[18eme belliard]) }
      it "is 'land_year_month'" do
        expect(loiret_workshop.name).to eq "Loiret_2022_3"
      end
      it "if tags are given is 'land_tag1_tag2_year_month'" do
        expect(paris_18_workshop.name).to eq "Paris_18eme_belliard_2022_1"
      end
    end
  end

  describe ".events" do
    context "are workshop participations" do
      let (:workshop_participants) { FactoryBot.create_list(:parent, 5) }
      let(:workshop) { FactoryBot.create(:workshop, participants: workshop_participants) }
      let(:paris_parent) { FactoryBot.create(:parent, postal_code: "75013") }
      let(:first_loiret_parent) { FactoryBot.create(:parent, postal_code: "45031") }
      let(:second_loiret_parent) { FactoryBot.create(:parent, postal_code: "45017") }
      let(:paris_workshop) { FactoryBot.create(:workshop, land: "Paris") }
      let(:loiret_workshop) { FactoryBot.create(:workshop, land: "Loiret") }
      let(:workshop_tag) { FactoryBot.create(:tag, name: "workshop_tag") }
      let(:tag_parent) { FactoryBot.create(:parent, tag_list: workshop_tag) }
      let(:tag_workshop) { FactoryBot.create(:workshop, tag_list: workshop_tag) }

      it "of chosen parents as participants" do
        expect(workshop.event_ids).not_to be_empty
        expect(workshop.event_ids).to match_array Event.workshop_participations.where(related: workshop_participants).pluck(:id)
      end
      # it "of chosen land's parents" do
        # expect(paris_workshop.event_ids).not_to be_empty
        # expect(paris_workshop.event_ids).to match_array Event.workshop_participations.where(related: paris_parent).pluck(:id)
        # expect(loiret_workshop.event_ids).to match_array Event.workshop_participations.where(related: [first_loiret_parent, second_loiret_parent]).pluck(:id)
      # end
      # it "of parents tagged with tags" do
      #   expect(Event.workshop_participations.where(related: tag_parent)).not_to be_empty
      #   expect(tag_workshop.event_ids).to match_array Event.workshop_participations.where(related: tag_parent).pluck(:id)
      # end

    end
  end
end
