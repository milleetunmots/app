# == Schema Information
#
# Table name: events
#
#  id           :bigint           not null, primary key
#  body         :text
#  discarded_at :datetime
#  occurred_at  :datetime
#  related_type :string
#  subject      :string
#  type         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  related_id   :bigint
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
    @other_event = FactoryBot.create(:other_event)
    @survey_response = FactoryBot.create(:survey_response)
    @text_message = FactoryBot.create(:text_message)
    @workshop_participation = FactoryBot.create(:workshop_participation)
    @admin = FactoryBot.create(:admin_user)
    @child = FactoryBot.create(:child, child_support: FactoryBot.create(:child_support, supporter: @admin))
    @parent = FactoryBot.create(:parent, parent1_children: [@child])
    @group = FactoryBot.create(:group, children: [@child])
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
        expect(Event.other_events).to match_array [@other_event]
      end
    end
  end

  describe "#survey_reponses" do
    context "returns" do
      it "survey responses" do
        expect(Event.survey_responses).to match_array [@survey_response]
      end
    end
  end

  describe "#text_messages" do
    context "returns" do
      it "text messages" do
        expect(Event.text_messages).to match_array [@text_message]
      end
    end
  end

  describe "#workshop_participations" do
    context "returns" do
      it "workshops" do
        expect(Event.workshop_participations).to match_array [@workshop_participation]
      end
    end
  end

  describe "#parent_first_child_group_id_in" do
    context "returns" do
      it "table of events with parent's first child in the group" do
        expect(Event.parent_first_child_group_id_in(@group.id).first).to eq @event
      end
    end
  end

  describe "#parent_first_child_supporter_id_in" do
    context "returns" do
      it "table of events with parent's first child supported by the parameter" do
        expect(Event.parent_first_child_supporter_id_in(@admin).first).to eq @event
      end
    end
  end
end
