# == Schema Information
#
# Table name: sources
#
#  id          :bigint           not null, primary key
#  channel     :string           not null
#  comment     :text
#  department  :integer
#  is_archived :boolean          default(FALSE), not null
#  name        :string           not null
#  utm         :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Source < ApplicationRecord

  include Discard::Model

  CHANNEL_LIST = %w[bao caf pmi local_partner other].freeze

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  has_many :children_sources, dependent: :nullify
  has_many :children, through: :children_sources
  has_many :external_users

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :name, presence: true
  validates :channel, presence: true, inclusion: { in: CHANNEL_LIST }
  validates_uniqueness_of :utm, allow_blank: true
  validate :department_required_if_pmi_or_caf, on: :create
  validate :uniq_name_by_channel

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :by_pmi, -> { where(channel: 'pmi').order(:department) }
  scope :by_caf, -> { where(channel: 'caf').order(:department) }
  scope :by_bao, -> { where(channel: 'bao').order(:id) }
  scope :by_local_partner, -> { where(channel: 'local_partner').order(:name) }
  scope :by_utm, ->(utm) { where(utm: utm) }
  scope :active, -> { where(is_archived: false) }
  scope :archived, -> { where(is_archived: true) }

  def archive!
    update!(is_archived: true)
  end

  def unarchive!
    update!(is_archived: false)
  end

  private

  def department_required_if_pmi_or_caf
    return unless %w[pmi caf].include?(channel) && department.blank?

    errors.add(:department, "doit être spécifié lorsque le canal est 'PMI' ou 'CAF'")
  end

  def uniq_name_by_channel
    duplicate =
      if new_record?
        Source.where(channel: channel, name: name).any?
      else
        Source.where(channel: channel, name: name).where.not(id: id).any?
      end
    return unless duplicate

    errors.add(:name, "doit être unique par canal d'inscription")
  end
end
