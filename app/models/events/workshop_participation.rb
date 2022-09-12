# == Schema Information
#
# Table name: events
#
#  id                  :bigint           not null, primary key
#  body                :text
#  discarded_at        :datetime
#  occurred_at         :datetime
#  originated_by_app   :boolean          default(TRUE), not null
#  parent_response     :string
#  related_type        :string
#  spot_hit_status     :integer
#  subject             :string
#  type                :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  related_id          :bigint
#  spot_hit_message_id :string
#  workshop_id         :bigint
#
# Indexes
#
#  index_events_on_discarded_at                 (discarded_at)
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

  after_create :send_message

  def send_message
    return unless related.available_for_workshops?

    return unless related.family_followed?

    return unless related.should_be_contacted?

    response_link = Rails.application.routes.url_helpers.edit_workshop_participation_url(
      parent_id: related.id,
      workshop_id: workshop.id
    )

    message = "#{workshop.invitation_message} Pour vous inscrire ou dire que vous ne venez pas, cliquer sur ce lien: #{response_link}"

    SpotHit::SendSmsService.new(
      related.id,
      DateTime.current.middle_of_day,
      message
    ).call
  end
end
