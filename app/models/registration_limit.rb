# == Schema Information
#
# Table name: registration_limits
#
#  id                      :bigint           not null, primary key
#  end_date                :date
#  is_archived             :boolean          default(FALSE), not null
#  limit                   :integer          not null
#  registration_form       :string           not null
#  registration_url_params :string
#  start_date              :date             not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  source_id               :bigint           not null
#
# Indexes
#
#  index_registration_limits_on_source_id  (source_id)
#
class RegistrationLimit < ApplicationRecord

  attr_accessor :without_end_date

  belongs_to :source

  validates :start_date, presence: true
  validate :end_date_not_in_past
  validate :end_date_not_before_start_date
  validate :registration_form_matches_source_channel
  validates :limit, presence: true, numericality: { only_integer: true }
  validates :registration_form, presence: true, inclusion: { in: Source::REGISTRATION_LINKS.pluck(:url) }

  scope :started, -> { where('start_date < ?', Time.zone.today) }
  scope :without_end_date, -> { where(end_date: nil) }
  scope :not_ended, -> { without_end_date.or(where('end_date >= ?', Time.zone.today)) }
  scope :ended, -> { where('end_date < ?', Time.zone.today) }
  scope :active, -> { started.not_ended.where(is_archived: false) }
  scope :archived, -> { where(is_archived: true) }

  delegate :children, :channel, to: :source, prefix: true

  def self.active_with_capacity
    where(id: active.reject(&:limit_reached?).pluck(:id))
  end

  def self.with_limit_reached
    where(id: all.select(&:limit_reached?).pluck(:id))
  end

  def self.with_capacity
    where(id: all.reject(&:limit_reached?).pluck(:id))
  end

  def archive!
    update!(is_archived: true)
  end

  def unarchive!
    update!(is_archived: false)
  end

  def children_count
    children = source_children.select { |child| child.created_at >= start_date }
    children = source_children.select { |child| child.created_at <= end_date } if end_date.present?
    children.count
  end

  def limit_reached?
    children_count >= limit
  end

  private

  def end_date_not_in_past
    if end_date.present? && end_date < Time.zone.today
      errors.add(:end_date, "ne peut pas être avant aujourd’hui")
    end
  end

  def end_date_not_before_start_date
    if end_date.present? && start_date.present? && end_date < start_date
      errors.add(:end_date, "ne peut pas être avant le début de la limite")
    end
  end

  def registration_form_matches_source_channel
    return if source.blank? || registration_form.blank?

    if registration_form == '/inscriptionmsa'
      return if source.msa?

      errors.add(:registration_form, 'doit correspondre au canal de la source.') && return
    end
    if source.msa?
      return if registration_form == '/inscriptionmsa'

      errors.add(:registration_form, 'doit correspondre au canal de la source.') && return
    end
    registration_link = Source::REGISTRATION_LINKS.find { |link| link[:url] == registration_form }
    return if registration_link[:channel] == source_channel

    errors.add(:registration_form, 'doit correspondre au canal de la source.')
  end
end
