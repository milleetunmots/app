# == Schema Information
#
# Table name: registration_limits
#
#  id                      :bigint           not null, primary key
#  end_date                :datetime
#  is_archived             :boolean          default(FALSE), not null
#  limit                   :integer          not null
#  registration_url_params :string
#  start_date              :datetime         not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  registration_link_id    :bigint           not null
#  source_id               :bigint           not null
#
# Indexes
#
#  index_registration_limits_on_registration_link_id  (registration_link_id)
#  index_registration_limits_on_source_id             (source_id)
#
class RegistrationLimit < ApplicationRecord

  attr_accessor :without_end_date

  belongs_to :source
  belongs_to :registration_link

  validates :start_date, presence: true
  validate :end_date_not_before_start_date
  validate :registration_form_matches_source_channel
  validates :limit, presence: true, numericality: { only_integer: true }

  scope :not_archived, -> { where(is_archived: false) }
  scope :archived, -> { where(is_archived: true) }
  scope :started, -> { not_archived.where('start_date < ?', Time.zone.now) }
  scope :without_end_date, -> { not_archived.where(end_date: nil) }
  scope :not_ended, -> { without_end_date.or(not_archived.where('end_date > ?', Time.zone.now)) }
  scope :ended, -> { not_archived.where('end_date < ?', Time.zone.today) }
  scope :reached, -> { where(id: not_archived.reject(&:open?).pluck(:id)) }
  scope :not_reached, -> { where(id: not_archived.select(&:open?).pluck(:id)) }
  scope :active, -> { started.not_ended }

  delegate :children, :channel, to: :source, prefix: true

  def archive!
    update!(is_archived: true)
  end

  def unarchive!
    update!(is_archived: false)
  end

  def started?
    start_date.past?
  end

  def ended?
    return false if end_date.nil?

    end_date.past?
  end

  def open?
    children_count < limit
  end

  def children_count
    children = source_children.select { |child| child.created_at > start_date }
    children = children.select { |child| child.created_at < end_date } if end_date.present?
    children.count
  end

  private

  def end_date_not_before_start_date
    return if end_date.blank? || start_date.blank? || end_date > start_date

    errors.add(:end_date, "ne peut pas être avant le début de la limite")
  end

  def registration_form_matches_source_channel
    return if source.blank? || registration_link.blank?

    if registration_link.url == '/inscriptionmsa'
      return if source.msa?

      errors.add(:registration_link, 'doit correspondre au canal de la source.') && return
    end
    if source.msa?
      return if registration_link.url == '/inscriptionmsa'

      errors.add(:registration_link, 'doit correspondre au canal de la source.') && return
    end
    return if registration_link.channel == source_channel

    errors.add(:registration_link, 'doit correspondre au canal de la source.')
  end
end
