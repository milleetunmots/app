class Place < ApplicationRecord
  PLACE_TYPES = %w[laep other].freeze

  validates :place_type, presence: true, inclusion: { in: PLACE_TYPES }
  validates :name, presence: true
  validates :address, presence: true

  geocoded_by :address
  reverse_geocoded_by :latitude, :longitude
end
