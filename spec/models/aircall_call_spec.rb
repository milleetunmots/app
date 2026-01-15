# == Schema Information
#
# Table name: aircall_calls
#
#  id                        :bigint           not null, primary key
#  answered                  :boolean
#  answered_at               :datetime
#  asset_url                 :string
#  call_session              :integer
#  call_uuid                 :string
#  direction                 :string
#  duration                  :integer
#  ended_at                  :datetime
#  missed_call_reason        :string
#  notes                     :text             default([]), is an Array
#  raw_transcription_payload :jsonb
#  started_at                :datetime
#  tags                      :text             default([]), is an Array
#  transcription_not_found   :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  aircall_id                :bigint
#  caller_id                 :bigint           not null
#  child_support_id          :bigint
#  parent_id                 :bigint
#
# Indexes
#
#  index_aircall_calls_on_call_uuid         (call_uuid)
#  index_aircall_calls_on_caller_id         (caller_id)
#  index_aircall_calls_on_child_support_id  (child_support_id)
#  index_aircall_calls_on_parent_id         (parent_id)
#
# Foreign Keys
#
#  fk_rails_...  (caller_id => admin_users.id)
#
require 'rails_helper'

RSpec.describe AircallCall, type: :model do
  subject { FactoryBot.create(:aircall_call) }
  let!(:answered_call) { FactoryBot.create(:aircall_call, answered: true) }
  let!(:missed_call) { FactoryBot.create(:aircall_call, answered: false) }

  describe 'Validations' do
    context 'success' do
      it 'if valid attributes are present' do
        expect(subject).to be_valid
      end
    end

    context 'fail' do
      it 'if aircall_id is missing' do
        subject.aircall_id = nil
        expect(subject).to_not be_valid
      end

      it 'if caller is missing' do
        subject.caller = nil
        expect(subject).to_not be_valid
      end

      it 'if call_uuid is missing' do
        subject.call_uuid = nil
        expect(subject).to_not be_valid
      end

      it 'if direction is missing' do
        subject.direction = nil
        expect(subject).to_not be_valid
      end

      it 'if direction is not provided by [inbound outbound]' do
        subject.direction = 'left'
        expect(subject).to_not be_valid
      end

    end
  end

  describe "#answered_calls" do
    context "returns" do
      it "aircall_call answered" do
        expect(described_class.answered_calls).to include(answered_call)
        expect(described_class.answered_calls).not_to include(missed_call)
        expect(described_class.answered_calls).to eq [answered_call]
      end
    end
  end

  describe "#missed_calls" do
    context "returns" do
      it "aircall_call missed" do
        expect(described_class.missed_calls).not_to include(answered_call)
        expect(described_class.missed_calls).to include(missed_call)
        expect(described_class.missed_calls).to eq [missed_call]
      end
    end
  end
end
