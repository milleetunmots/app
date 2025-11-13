# == Schema Information
#
# Table name: registration_links
#
#  id         :bigint           not null, primary key
#  channel    :string           not null
#  label      :string           not null
#  url        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_registration_links_on_label  (label) UNIQUE
#  index_registration_links_on_url    (url) UNIQUE
#
class RegistrationLink < ApplicationRecord
  has_many :registration_limits

  validates :url, presence: true, uniqueness: true
  validates :channel, presence: true, inclusion: { in: Source::CHANNEL_LIST }
  validates :label, presence: true, uniqueness: true
end