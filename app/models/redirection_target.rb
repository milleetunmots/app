# == Schema Information
#
# Table name: redirection_targets
#
#  id                                  :bigint           not null, primary key
#  name                                :string
#  redirection_url_unique_visits_count :integer
#  redirection_url_visits_count        :integer
#  redirection_urls_count              :integer
#  target_url                          :string           not null
#  unique_visit_rate                   :float
#  visit_rate                          :float
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#

class RedirectionTarget < ApplicationRecord

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  has_many :redirection_urls, dependent: :destroy

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :target_url, presence: true

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  def update_counters!
    self.redirection_urls_count = redirection_urls.count

    if self.redirection_urls_count.zero?
      self.redirection_url_unique_visits_count = 0
      self.unique_visit_rate = 0
      self.redirection_url_visits_count = 0
      self.visit_rate = 0
    else
      self.redirection_url_unique_visits_count = redirection_urls.with_visits.count
      self.unique_visit_rate = redirection_url_unique_visits_count / redirection_urls_count.to_f
      self.redirection_url_visits_count = redirection_urls.sum(:redirection_url_visits_count)
      self.visit_rate = redirection_url_visits_count / redirection_urls_count.to_f
    end

    save!
  end

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail

end
