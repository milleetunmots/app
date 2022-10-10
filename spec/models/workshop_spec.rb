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
#  land               :string
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
      let(:workshop) { FactoryBot.create(:workshop, workshop_date: Date.today.next_day()) }
      let(:paris_18_workshop) { FactoryBot.create(:workshop, workshop_date: Date.today.next_day(2), land_list: %w[Paris_18_eme]) }

      it "is 'Atelier_year_month' if tags are not given" do
        expect(workshop.name).to eq "Atelier_#{Date.today.next_day().year}_#{Date.today.next_day().month}"
      end
      it "if land_tag are given is 'land_tag1_tag2_year_month'" do
        expect(paris_18_workshop.name).to eq "Atelier_Paris_18_eme_#{Date.today.next_day().year}_#{Date.today.next_day().month}"
      end
    end
  end

  # describe ".events" do
  #   context "are workshop participations" do
  #     let(:workshop_participants) { FactoryBot.create_list(:parent, 5) }
  #     let(:workshop) { FactoryBot.create(:workshop, participants: workshop_participants) }
  #     let(:land_parent) { FactoryBot.create(:parent, postal_code: '75018') }
  #     let(:land_child) { FactoryBot.create(:child, parent1: land_parent )}
  #     let(:land_workshop) { FactoryBot.create(:workshop, land_list: "paris 18 eme") }
      # let(:participants) { FactoryBot.create_list(:parent, 3) }
      # let(:parent) { FactoryBot.create(:parent, tag_list: "tag_test") }
      # let(:both_workshop) { FactoryBot.create(:workshop, participants: participants, tag_list: "tag_test") }

      # it "of chosen parents as participants" do
      #   expect(workshop.event_ids).not_to be_empty
      #   expect(workshop.event_ids).to match_array Event.workshop_participations.where(related: workshop_participants).pluck(:id)
      # end

      # it "of parents tagged with tags" do
      #   expect(land_parent).not_to be_nil
      #   expect(land_workshop.event_ids).not_to be_empty
      #   expect(land_workshop.event_ids).to match_array Event.workshop_participations.where(related: land_parent).pluck(:id)
      # end
      #
      # it "of parents tagged with tags and chosen parents" do
      #   expect(parent).not_to be_nil
      #   expect(both_workshop.event_ids).not_to be_empty
      #   expect(both_workshop.event_ids.count).to eq 4
      #   expect(both_workshop.event_ids).to match_array Event.workshop_participations.where(related: participants + [parent]).pluck(:id)
      # end
  #   end
  # end
end
