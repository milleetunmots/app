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

class Events::TextMessage < Event

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :body, presence: true

  # ---------------------------------------------------------------------------
  # callbacks
  # ---------------------------------------------------------------------------

  after_save :tag_children, if: -> { saved_change_to_spot_hit_status? && spot_hit_status == 4 && quit_group_child_id.present? }

  def tag_children
    quit_group_child.tag_list.add("echec-sms-#{Time.zone.today.strftime("%Y-%m-%d")}")
    quit_group_child.group_status = 'active' if quit_group_child.group_status == 'paused'
    quit_group_child.save!
  end
end
