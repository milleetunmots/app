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

class RedirectionUrlSent < ApplicationRecord

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :redirection_url

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :occurred_at, presence: true

end
