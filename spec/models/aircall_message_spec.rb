# == Schema Information
#
# Table name: aircall_messages
#
#  id               :bigint           not null, primary key
#  body             :text
#  direction        :string
#  sent_at          :datetime
#  status           :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  aircall_id       :string
#  caller_id        :bigint           not null
#  child_support_id :bigint
#  parent_id        :bigint
#
# Indexes
#
#  index_aircall_messages_on_aircall_id        (aircall_id)
#  index_aircall_messages_on_caller_id         (caller_id)
#  index_aircall_messages_on_child_support_id  (child_support_id)
#  index_aircall_messages_on_parent_id         (parent_id)
#
# Foreign Keys
#
#  fk_rails_...  (caller_id => admin_users.id)
#
require 'rails_helper'

RSpec.describe AircallMessage, type: :model do
  subject { FactoryBot.create(:aircall_message) }

  describe 'Validations' do
    context 'success' do
      it 'if valid attributes are present' do
        expect(subject).to be_valid
      end
    end

    context 'fail' do
      it 'if aircall_id is missing' do
        subject.aircall_id = nil
        expect(subject).not_to be_valid
      end

      it 'if aircall_id is not unique' do
        existing_message = FactoryBot.create(:aircall_message, aircall_id: '12345')
        subject.aircall_id = '12345'
        expect(subject).not_to be_valid
      end

      it 'if direction is missing' do
        subject.direction = nil
        expect(subject).not_to be_valid
      end

      it 'if direction is not in [inbound outbound]' do
        subject.direction = 'invalid'
        expect(subject).not_to be_valid
      end

      it 'if parent is missing' do
        subject.parent = nil
        expect(subject).not_to be_valid
      end

      it 'if caller is missing' do
        subject.caller = nil
        expect(subject).not_to be_valid
      end
    end
  end
end
