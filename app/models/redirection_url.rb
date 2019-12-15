# == Schema Information
#
# Table name: redirection_urls
#
#  id                           :bigint           not null, primary key
#  owner_type                   :string
#  redirection_url_visits_count :integer
#  security_code                :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  owner_id                     :bigint
#  redirection_target_id        :bigint
#
# Indexes
#
#  index_redirection_urls_on_owner_type_and_owner_id  (owner_type,owner_id)
#  index_redirection_urls_on_redirection_target_id    (redirection_target_id)
#

class RedirectionUrl < ApplicationRecord

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :redirection_target, counter_cache: true
  belongs_to :owner, polymorphic: true

  has_many :redirection_url_visits, dependent: :destroy

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :security_code, presence: true

  # ---------------------------------------------------------------------------
  # callbacks
  # ---------------------------------------------------------------------------

  def initialize(attributes = {})
    super
    self.security_code = SecureRandom.hex(2)
  end

  after_touch :update_redirection_target_counters!
  def update_redirection_target_counters!
    redirection_target.update_counters!
  end

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :with_visits, -> { where("redirection_url_visits_count > 0") }

end
