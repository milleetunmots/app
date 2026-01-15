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
class AircallCall < ApplicationRecord
	belongs_to :child_support, optional: true
	belongs_to :parent, optional: true
	belongs_to :caller, class_name: 'AdminUser'

	validates :aircall_id, presence: true
	validates :call_uuid, presence: true, uniqueness: true
	validates :direction, inclusion: { in: %w[inbound outbound] }

	scope :answered_calls, -> { where(answered: true) }
	scope :missed_calls, -> { where(answered: false) }
end
