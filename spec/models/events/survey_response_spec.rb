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

RSpec.describe Events::SurveyResponse, type: :model do
  describe "Validations" do
    context "succeed" do
      it "if minimal attributes are present" do
        expect(FactoryBot.build_stubbed(:survey_response)).to be_valid
      end
    end

    context "fail" do
      it "if the survey doesn't have a body" do
        expect(FactoryBot.build_stubbed(:survey_response, body: nil)).not_to be_valid
      end

      it "if the survey doesn't have a survey_name" do
        expect(FactoryBot.build_stubbed(:survey_response, subject: nil)).not_to be_valid
      end
    end
  end

  describe "#survey_names" do
    context "returns" do
      it "the subjects" do
        first_survey = FactoryBot.create(:survey_response, subject: "first_subject")
        second_survey = FactoryBot.create(:survey_response, subject: "first_subject")
        third_survey = FactoryBot.create(:survey_response, subject: "second_subject")
        expect(Events::SurveyResponse.survey_names).to match_array [first_survey.subject, third_survey.subject]
      end
    end
  end
end
