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

class Events::WorkshopParticipation < Event

  # ---------------------------------------------------------------------------
  # attributes
  # ---------------------------------------------------------------------------

  alias_attribute :comments, :body
  alias_attribute :workshop_invitation_response, :response
  alias_attribute :workshop_presence, :presence

end
