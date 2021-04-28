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
end
