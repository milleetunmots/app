# == Schema Information
#
# Table name: redirection_url_visits
#
#  id                 :bigint           not null, primary key
#  occurred_at        :datetime
#  redirection_url_id :bigint
#
# Indexes
#
#  index_redirection_url_visits_on_redirection_url_id  (redirection_url_id)
#

class RedirectionUrlVisit < ApplicationRecord

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  # use touch: true here to trigger #after_touch on redirection_url
  belongs_to :redirection_url, counter_cache: true, touch: true

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :occurred_at, presence: true

end
