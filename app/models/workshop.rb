class Workshop < ApplicationRecord
  include Discard::Model

  belongs_to :animator, class_name: "AdminUser"
  has_many :events, dependent: :delete_all
  has_many :participants, through: :events, as: :related, source_type: :Parent

  validates :title,
    presence: true,
    uniqueness: {case_sensitive: false}

  # validates :animator,
  #   presence: true
  validates :occurred_at,
    presence: true
  validates :address,
    presence: true
  validates :postal_code,
    presence: true
  validates :city_name,
    presence: true
  validates :invitation_message,
    presence: true
end
