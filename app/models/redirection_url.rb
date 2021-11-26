# == Schema Information
#
# Table name: redirection_urls
#
#  id                           :bigint           not null, primary key
#  discarded_at                 :datetime
#  redirection_url_visits_count :integer
#  security_code                :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  child_id                     :bigint
#  parent_id                    :bigint
#  redirection_target_id        :bigint
#
# Indexes
#
#  index_redirection_urls_on_child_id               (child_id)
#  index_redirection_urls_on_discarded_at           (discarded_at)
#  index_redirection_urls_on_parent_id              (parent_id)
#  index_redirection_urls_on_redirection_target_id  (redirection_target_id)
#

class RedirectionUrl < ApplicationRecord

  include Discard::Model

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :redirection_target
  belongs_to :parent
  belongs_to :child

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
    self.security_code = SecureRandom.hex(1)
  end

  after_touch :update_relation_counters!
  after_save :update_relation_counters!
  after_destroy :update_relation_counters!

  def update_relation_counters!
    redirection_target.update_counters!
    parent.update_counters!
    # we cannot just do `child.update_counters!` because the family could
    # contain other children
    parent.children.each(&:update_counters!)
  end

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :with_visits, -> { where("redirection_url_visits_count > 0") }

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  delegate :medium_name,
    :medium_url,
    to: :redirection_target,
    prefix: true

  delegate :address,
    :city_name,
    :first_name,
           # :gender,
    :last_name,
    :letterbox_name,
    :phone_number_national,
    :postal_code,
    to: :parent,
    prefix: true

  delegate :birthdate,
    :first_name,
           # :gender,
    :group_name,
    :group_status,
    :last_name,
    :registration_source,
    :registration_source_details,
    to: :child,
    prefix: true
end
