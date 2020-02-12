# == Schema Information
#
# Table name: events
#
#  id           :bigint           not null, primary key
#  body         :text
#  discarded_at :datetime
#  occurred_at  :datetime
#  related_type :string
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

class Events::TextMessage < Event

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :body, presence: true

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  delegate :first_child,
           to: :related,
           prefix: true,
           allow_nil: true

  delegate :id,
           to: :related_first_child,
           prefix: true,
           allow_nil: true

end
