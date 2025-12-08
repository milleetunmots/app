# == Schema Information
#
# Table name: places
#
#  id                    :bigint           not null, primary key
#  address               :text             not null
#  latitude              :float
#  longitude             :float
#  name                  :string           not null
#  place_type            :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  redirection_target_id :bigint
#
# Indexes
#
#  index_places_on_redirection_target_id  (redirection_target_id)
#
# Foreign Keys
#
#  fk_rails_...  (redirection_target_id => redirection_targets.id)
#
class Place < ApplicationRecord
  PLACE_TYPES = %w[laep other].freeze

  belongs_to :redirection_target, optional: true

  validates :place_type, presence: true, inclusion: { in: PLACE_TYPES }
  validates :name, presence: true
  validates :address, presence: true

  scope :laep, -> { where(place_type: 'laep') }

  geocoded_by :address
  reverse_geocoded_by :latitude, :longitude

  def city
    address.split(/\s+/).last
  end
end
