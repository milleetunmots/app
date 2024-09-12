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
#  redirection_urls_count                     :integer
#  created_at                                 :datetime         not null
#  updated_at                                 :datetime         not null
#  medium_id                                  :bigint
#
# Indexes
#
#  index_redirection_targets_on_discarded_at  (discarded_at)
#  index_redirection_targets_on_medium_id     (medium_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (medium_id => media.id)
#

class RedirectionTarget < ApplicationRecord

  include Discard::Model

  SUGGESTED_VIDEOS_MODULE_0_NAME_STARTS_WITH = 'Module 0 - Conversations'.freeze
  SUGGESTED_VIDEOS_MODULE_1_NAME_STARTS_WITH = 'Lecture - Pour debuter'.freeze
  SUGGESTED_VIDEOS_CALL_3_NAME_STARTS_WITH = 'Appel 3'.freeze
  SUGGESTED_VIDEOS = [SUGGESTED_VIDEOS_MODULE_0_NAME_STARTS_WITH, SUGGESTED_VIDEOS_MODULE_1_NAME_STARTS_WITH, SUGGESTED_VIDEOS_CALL_3_NAME_STARTS_WITH].freeze

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :medium
  has_many :redirection_urls, dependent: :destroy
  has_many :children, through: :redirection_urls

  # ---------------------------------------------------------------------------
  # attributes
  # ---------------------------------------------------------------------------

  delegate :name,
    :url,
    to: :medium,
    prefix: true

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

  def suggested_videos?
    SUGGESTED_VIDEOS.any? { |suggested_video_name| medium.name.include?(suggested_video_name) }
  end
end
