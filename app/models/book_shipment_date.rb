# == Schema Information
#
# Table name: book_shipment_dates
#
#  id         :bigint           not null, primary key
#  date       :date             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_book_shipment_dates_on_date  (date) UNIQUE
#
class BookShipmentDate < ApplicationRecord

  CYCLE_DAYS = 45

  validates :date, presence: true, uniqueness: true

  scope :upcoming, -> { where(date: Date.current..).order(:date) }

  def self.next_suggested_date
    base = (order(:date).last&.date || Date.current) + CYCLE_DAYS.days
    base.monday? ? base : base.next_occurring(:monday)
  end
end
