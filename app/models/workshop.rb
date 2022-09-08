# == Schema Information
#
# Table name: workshops
#
#  id                 :bigint           not null, primary key
#  address            :string           not null
#  city_name          :string           not null
#  co_animator        :string
#  discarded_at       :datetime
#  invitation_message :text             not null
#  name               :string
#  postal_code        :string           not null
#  topic              :string           not null
#  workshop_date      :date             not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  animator_id        :bigint           not null
#
# Indexes
#
#  index_workshops_on_animator_id  (animator_id)
#
# Foreign Keys
#
#  fk_rails_...  (animator_id => admin_users.id)
#
class Workshop < ApplicationRecord
  include Discard::Model

  acts_as_taggable_on :lands

  TOPICS = %w[meal sleep nursery_rhymes books games outside bath emotion]

  belongs_to :animator, class_name: "AdminUser"
  has_many :events, dependent: :delete_all
  has_many :participants, through: :events, as: :related, source: :related, source_type: :Parent

  accepts_nested_attributes_for :events

  before_validation :set_name, :set_workshop_participation, :set_workshop_tag_participants, on: :create

  validates :topic,
    presence: true,
    inclusion: {in: TOPICS}
  validates :animator,
    presence: true
  validates :workshop_date,
    presence: true
  validates :workshop_date, date: {
    after: proc { Date.today }
  }, on: :create
  validates :address,
    presence: true
  validates :postal_code,
    presence: true
  validates :city_name,
    presence: true
  validates :invitation_message,
    presence: true

  validates_associated :events

  after_create do |workshop|
    message = workshop.invitation_message
    parent_ids = workshop.participant_ids + Parent.tagged_with(workshop.land_list.join(", ")).pluck(:id)

    parent_ids.each do |participant_id|
      parent = Parent.find(participant_id)

      next unless parent.available_for_workshops?

      next unless parent.family_followed?

      next unless parent.should_be_contacted?

      response_link = Rails.application.routes.url_helpers.edit_workshop_participation_url(
        parent_id: participant_id,
        workshop_id: workshop.id
      )

      workshop.invitation_message = "#{message} Pour vous inscrire ou dire que vous ne venez pas, cliquer sur ce lien: #{response_link}"
      service = SpotHit::SendSmsService.new(
        participant_id,
        DateTime.current.middle_of_day,
        workshop.invitation_message
      ).call
      if service.errors.any?
        alert = service.errors.join("\n")
        raise StandardError, alert
      end
    end
  end

  def set_name
    self.name = "#{workshop_date.year}_#{workshop_date.month}"
    self.name = land_list.empty? ? "Atelier_#{name}" : "#{land_list.join("_")}_#{name}"
  end

  def set_workshop_tag_participants
    Parent.tagged_with(land_list.join(", ")).each do |parent|
      events.build(
        type: "Events::WorkshopParticipation",
        workshop: self,
        related: parent,
        body: name,
        occurred_at: workshop_date
      )
    end
  end

  def set_workshop_participation
    events.each do |participation|
      participation.occurred_at = workshop_date
      participation.type = "Events::WorkshopParticipation"
      participation.body = name
    end
  end
end
