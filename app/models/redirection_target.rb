# == Schema Information
#
# Table name: redirection_targets
#
#  id                                         :bigint           not null, primary key
#  discarded_at                               :datetime
#  family_redirection_url_unique_visits_count :integer
#  family_redirection_url_visits_count        :integer
#  family_redirection_urls_count              :integer
#  family_unique_visit_rate                   :float
#  family_visit_rate                          :float
#  name                                       :string
#  redirection_urls_count                     :integer
#  target_url                                 :string           not null
#  created_at                                 :datetime         not null
#  updated_at                                 :datetime         not null
#
# Indexes
#
#  index_redirection_targets_on_discarded_at  (discarded_at)
#

class RedirectionTarget < ApplicationRecord

  include Discard::Model

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  has_many :redirection_urls, dependent: :destroy
  has_many :children, through: :redirection_urls

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :target_url, presence: true

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  def update_counters!
    self.redirection_urls_count = redirection_urls.count
    self.family_redirection_urls_count = redirection_urls.count('DISTINCT child_id')

    if self.family_redirection_urls_count.zero?
      self.family_redirection_url_unique_visits_count = 0
      self.family_unique_visit_rate = 0
      self.family_redirection_url_visits_count = 0
      self.family_visit_rate = 0
    else
      # family counters : if both parents receive a link and only
      # 1 parent opens it, we consider it 100% visited

      self.family_redirection_urls_count = redirection_urls.count('DISTINCT child_id')
      self.family_redirection_url_unique_visits_count = redirection_urls.with_visits.count('DISTINCT child_id')
      self.family_unique_visit_rate = family_redirection_url_unique_visits_count / family_redirection_urls_count.to_f
      self.family_redirection_url_visits_count = redirection_urls.sum(:redirection_url_visits_count)
      self.family_visit_rate = family_redirection_url_visits_count / family_redirection_urls_count.to_f
    end

    save!
  end

end
