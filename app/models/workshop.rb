class Workshop < ApplicationRecord
  include Discard::Model

  belongs_to :animator, class_name: "AdminUser"
  has_many :events, dependent: :delete_all
  has_many :participants, through: :events, as: :related, source: :related, source_type: :Parent

  accepts_nested_attributes_for :events

  before_validation :set_workshop_participation, on: :create

  validates :name,
    presence: true,
    uniqueness: {case_sensitive: false}
  validates :animator,
    presence: true
  validates :workshop_date,
    presence: true
  validates :address,
    presence: true
  validates :postal_code,
    presence: true
  validates :city_name,
    presence: true
  validates :invitation_message,
    presence: true

  validates_associated :events

  def set_workshop_participation
    events.each do |participation|
      participation.occurred_at = workshop_date
      participation.type = "Events::WorkshopParticipation"
      participation.body = description
      participation.save(validate: false)
    end
  end
end
