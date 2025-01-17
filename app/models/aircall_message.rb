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
class AircallMessage < ApplicationRecord
	belongs_to :child_support, optional: true
	belongs_to :parent
	belongs_to :caller, class_name: 'AdminUser'

	validates :aircall_id, presence: true, uniqueness: true
	validates :direction, inclusion: { in: %w[inbound outbound] }
	validates :status, inclusion: { in: %w[sent delivered received] }
	# Aircall -> external : Status “sent” and then “delivered”
  # External -> Aircall : Status “received”
end
