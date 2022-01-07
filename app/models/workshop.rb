class Workshop < ApplicationRecord
  include Discard::Model

  # before_save :set_workshop_participation

  belongs_to :animator, class_name: "AdminUser"
  has_many :events, dependent: :delete_all
  has_many :participants, through: :events, as: :related, source: :related, source_type: :Parent

  accepts_nested_attributes_for :events

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

  # def set_workshop_participation
  #   events.each do |participation|
  #     participation.occurred_at = workshop_date
  #     participation.subject = name
  #     participation.body = description
  #   end
  # end
end
