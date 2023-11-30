# == Schema Information
#
# Table name: sources
#
#  id         :bigint           not null, primary key
#  channel    :string           not null
#  comment    :text
#  department :integer
#  name       :string           not null
#  utm        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Source < ApplicationRecord

  include Discard::Model

  CHANNEL_LIST = %w[bao caf pmi local_partner].freeze

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  has_many :children_sources, dependent: :nullify
  has_many :children, through: :children_sources

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :channel, presence: true, inclusion: { in: CHANNEL_LIST }
  validate :department_required_if_pmi_or_caf, on: :create

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :by_pmi, -> { where(channel: 'pmi').order(:name) }
  scope :by_caf, -> { where(channel: 'caf').order(:name) }
  scope :by_bao, -> { where(channel: 'bao').order(:name) }
  scope :by_local_partner, -> { where(channel: 'local_partner').order(:name) }
  scope :by_utm, ->(utm) { where(utm: utm) }

  private

  def department_required_if_pmi_or_caf
    return unless %w[pmi caf].include?(channel) && department.blank?

    errors.add(:department, "doit être spécifié lorsque le canal est 'PMI' ou 'CAF'")
  end
end
