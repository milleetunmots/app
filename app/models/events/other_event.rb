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
#  message_provider          :string
#  occurred_at               :datetime
#  originated_by_app         :boolean          default(TRUE), not null
#  parent_presence           :string
#  parent_response           :string
#  related_type              :string
#  spot_hit_status           :integer
#  subject                   :string
#  type                      :string
#  workshop_time_slot        :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  aircall_message_id        :string
#  quit_group_child_id       :bigint
#  related_id                :bigint
#  spot_hit_message_id       :string
#  spot_hit_rcs_id           :string
#  workshop_id               :bigint
#
# Indexes
#
#  index_events_on_discarded_at                  (discarded_at)
#  index_events_on_quit_group_child_id           (quit_group_child_id)
#  index_events_on_related_type_and_related_id   (related_type,related_id)
#  index_events_on_spot_hit_rcs_id               (spot_hit_rcs_id)
#  index_events_on_type                          (type)
#  index_events_on_type_and_spot_hit_message_id  (type,spot_hit_message_id)
#  index_events_on_workshop_id                   (workshop_id)
#
# Foreign Keys
#
#  fk_rails_...  (workshop_id => workshops.id)
#

class Events::OtherEvent < Event

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :body, presence: true

end
