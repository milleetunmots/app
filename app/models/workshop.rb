class Workshop < ApplicationRecord
  include Discard::Model

  belongs_to :animator, class_name: "AdminUser"
  # has_many :events
  # has_many :related, through: :events

  # accepts_nested_attributes_for :related
end
