# == Schema Information
#
# Table name: events
#
#  id                  :bigint           not null, primary key
#  body                :text
#  discarded_at        :datetime
#  occurred_at         :datetime
#  originated_by_app   :boolean          default(TRUE), not null
#  related_type        :string
#  spot_hit_status     :integer
#  subject             :string
#  type                :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  related_id          :bigint
#  spot_hit_message_id :string
#
# Indexes
#
#  index_events_on_discarded_at                 (discarded_at)
#  index_events_on_related_type_and_related_id  (related_type,related_id)
#  index_events_on_type                         (type)
#

require "rails_helper"

RSpec.describe Event, type: :model do
  before(:each) do
    @other_event1 = FactoryBot.create(:other_event)
    @other_event2 = FactoryBot.create(:other_event)
    @survey_response1 = FactoryBot.create(:survey_response)
    @survey_response2 = FactoryBot.create(:survey_response)
    @text_message1 = FactoryBot.create(:text_message)
    @text_message2 = FactoryBot.create(:text_message)
    @workshop_participation1 = FactoryBot.create(:workshop_participation)
    @workshop_participation2 = FactoryBot.create(:workshop_participation)
    @admin = FactoryBot.create(:admin_user)
    @group = FactoryBot.create(:group)
    @child = FactoryBot.create(:child, child_support: FactoryBot.create(:child_support, supporter: @admin), group: @group, group_status: "active")
    @parent = FactoryBot.create(:parent, parent1_children: [@child])
    @event = FactoryBot.create(:event, related: @parent)
  end

  describe "Validations" do
    context "succeed" do
      it "if event has been occurred" do
        expect(FactoryBot.build_stubbed(:event)).to be_valid
      end
    end

    context "fail" do
      it "if event hasn't been occurred" do
        expect(FactoryBot.build_stubbed(:event, occurred_at: nil)).not_to be_valid
      end
    end
  end

  describe "#other_events" do
    context "returns" do
      it "other events" do
        expect(Event.other_events).to match_array [@other_event1, @other_event2]
      end
    end
  end

  describe "#survey_reponses" do
    context "returns" do
      it "survey responses" do
        expect(Event.survey_responses).to match_array [@survey_response1, @survey_response2]
      end
    end
  end

  describe "#text_messages" do
    context "returns" do
      it "text messages" do
        expect(Event.text_messages).to match_array [@text_message1, @text_message2]
      end
    end
  end

  describe "#workshop_participations" do
    context "returns" do
      it "workshops" do
        expect(Event.workshop_participations).to match_array [@workshop_participation1, @workshop_participation2]
      end
    end
  end

  describe "#parent_first_child_group_id_in" do
    context "returns" do
      it "table of events with parent's first child in the group" do
        expect(Event.parent_first_child_group_id_in(@group.id)).to match_array [@event]
      end
    end
  end

  describe "#parent_first_child_supporter_id_in" do
    context "returns" do
      it "table of events with parent's first child supported by the parameter" do
        expect(Event.parent_first_child_supporter_id_in(@admin)).to match_array [@event]
      end
    end
  end

  describe "#ransackable_scopes" do
    context "returns" do
      it "ransackable scopes" do
        expect(Event.ransackable_scopes).to eq %i[parent_first_child_group_id_in parent_first_child_supporter_id_in]
      end
    end
  end
end
