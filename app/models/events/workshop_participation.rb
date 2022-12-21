# == Schema Information
#
# Table name: events
#
#  id                  :bigint           not null, primary key
#  acceptation_date    :date
#  body                :text
#  discarded_at        :datetime
#  occurred_at         :datetime
#  originated_by_app   :boolean          default(TRUE), not null
#  parent_presence     :boolean          default(FALSE)
#  parent_response     :string
#  related_type        :string
#  spot_hit_status     :integer
#  subject             :string
#  type                :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  quit_group_child_id :bigint
#  related_id          :bigint
#  spot_hit_message_id :string
#  workshop_id         :bigint
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

class Events::WorkshopParticipation < Event

  # ---------------------------------------------------------------------------
  # attributes
  # ---------------------------------------------------------------------------

  alias_attribute :comments, :body
  alias_attribute :workshop_invitation_response, :response
  alias_attribute :workshop_presence, :presence

end
