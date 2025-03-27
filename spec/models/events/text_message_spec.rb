# == Schema Information
#
# Table name: events
#
#  id                        :bigint           not null, primary key
#  acceptation_date          :date
#  body                      :text
#  discarded_at              :datetime
#  is_support_module_message :boolean          default(FALSE), not null
#  link_sent_substring       :string
#  occurred_at               :datetime
#  originated_by_app         :boolean          default(TRUE), not null
#  parent_presence           :string
#  parent_response           :string
#  related_type              :string
#  spot_hit_status           :integer
#  subject                   :string
#  type                      :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  aircall_message_id        :string
#  quit_group_child_id       :bigint
#  related_id                :bigint
#  spot_hit_message_id       :string
#  workshop_id               :bigint
#
# Indexes
#
#  index_events_on_discarded_at                 (discarded_at)
#  index_events_on_quit_group_child_id          (quit_group_child_id)
#  index_events_on_related_type_and_related_id  (related_type,related_id)
#  index_events_on_type                         (type)
#  index_events_on_workshop_id                  (workshop_id)
#
# Foreign Keys
#
#  fk_rails_...  (workshop_id => workshops.id)
#

require "rails_helper"

RSpec.describe Events::TextMessage, type: :model do
  describe "Validations" do
    context "succeed" do
      it "if the text message have a body" do
        expect(FactoryBot.build_stubbed(:text_message)).to be_valid
      end
    end

    context "fail" do
      it "if the text message doesn't have a body" do
        expect(FactoryBot.build_stubbed(:text_message, body: nil)).not_to be_valid
      end
    end
  end
end
