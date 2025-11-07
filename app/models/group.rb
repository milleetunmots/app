# == Schema Information
#
# Table name: groups
#
#  id                         :bigint           not null, primary key
#  call0_end_date             :date
#  call0_start_date           :date
#  call1_end_date             :date
#  call1_start_date           :date
#  call2_end_date             :date
#  call2_start_date           :date
#  call3_end_date             :date
#  call3_start_date           :date
#  discarded_at               :datetime
#  enable_calls_recording     :boolean          default(FALSE), not null
#  ended_at                   :date
#  expected_children_number   :integer
#  is_excluded_from_analytics :boolean          default(FALSE), not null
#  is_programmed              :boolean          default(FALSE), not null
#  name                       :string
#  started_at                 :date
#  support_module_programmed  :integer          default(0)
#  support_module_sent_dates  :jsonb
#  support_modules_count      :integer          default(0), not null
#  type_of_support            :string           default("with_calls")
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
# Indexes
#
#  index_groups_on_discarded_at  (discarded_at)
#  index_groups_on_ended_at      (ended_at)
#  index_groups_on_started_at    (started_at)
#

class Group < ApplicationRecord

  include Discard::Model

  MAX_GROUP_SUPPORT_MODULES_COUNT = ENV['MAX_GROUP_SUPPORT_MODULES_COUNT'].to_i.freeze
  TYPE_OF_SUPPORT_OPTIONS = %w[with_calls without_calls].freeze

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  has_many :children, dependent: :nullify
  has_many :parent1, through: :children
  has_many :parent2, through: :children
  has_many :child_supports, through: :children
  has_many :supporters, through: :child_supports

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false }
  validates :expected_children_number, presence: true, on: :create
  validates :support_modules_count, numericality: { only_integer: true, less_than_or_equal_to: MAX_GROUP_SUPPORT_MODULES_COUNT }, presence: true
  validates :started_at, presence: true, on: :create
  validates :type_of_support, inclusion: { in: TYPE_OF_SUPPORT_OPTIONS }
  validate :started_at_only_monday

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :not_ended, -> { where('ended_at IS NULL OR ended_at > ?', Time.zone.today) }
  scope :ended, -> { where('ended_at <= ?', Time.zone.today) }
  scope :not_started, -> { where('started_at >= ? AND support_module_programmed = ?', Time.zone.today, 0) }
  scope :started, -> { where('started_at < ? OR support_module_programmed > ?', Time.zone.today, 0) }
  scope :excluded_from_analytics, -> { where(is_excluded_from_analytics: true) }
  scope :with_calls, -> { where(type_of_support: 'with_calls') }
  scope :without_calls, -> { where(type_of_support: 'without_calls') }

  # ---------------------------------------------------------------------------
  # callbacks
  # ---------------------------------------------------------------------------

  before_create :standardize_name
  before_create :set_calls_dates
  before_save :set_calls_dates, if: :will_save_change_to_started_at?
  after_create :add_waiting_children

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  def started?
    started_at.past?
  end

  def is_ended?
    ended_at && ended_at <= Time.zone.today
  end

  def is_not_ended?
    !is_ended?
  end

  def self.group_active
    where('started_at <= ? AND (ended_at IS NULL OR ended_at > ?)', Time.zone.today, Time.zone.today)
  end

  def self.group_ended
    where('ended_at < ?', Time.zone.today)
  end

  def self.group_next
    where('started_at > ?', Time.zone.today)
  end

  def target_group?
    !name.match?('Popi')
  end

  def self.not_target_group
    where('unaccent(name) ILIKE unaccent(?)', '%popi%')
  end

  def self.next_available_at(date)
    next_available_groups = where(is_programmed: false).where('started_at > ?', date).order(:started_at)

    next_available_groups.each do |next_available_group|
      return next_available_group if next_available_group.children.count < next_available_group.expected_children_number.to_i

      next
    end
    nil
  end

  def started_at_only_monday
    errors.add(:started_at, :invalid, message: 'doit être un lundi') if started_at && !started_at.monday?
  end

  def bilingual_children
    children.joins(:child_support).where(child_supports: { is_bilingual: '0_yes' })
  end

  def with_module_zero?
    return false if started_at.nil?

    started_at >= DateTime.parse(ENV['MODULE_ZERO_FEATURE_START'])
  end

  def active_children_ids
    children.active_group.ids
  end

  def add_waiting_children
    # Add waiting children to next available group for them (could be another group)
    Child::AddWaitingChildrenToGroupJob.perform_later
  end

  def standardize_name
    self.name = "#{started_at.strftime('%Y/%m/%d')} - #{name}"
  end

  def set_calls_dates
    # call 0
    self.call0_start_date = started_at
    self.call0_end_date = started_at + 13.days
    # call 1
    self.call1_start_date = started_at + 28.days
    self.call1_end_date = started_at + 41.days
    # call 2
    self.call2_start_date = started_at + 56.days
    self.call2_end_date = started_at + 76.days
    # call 3
    self.call3_start_date = started_at + 154.days
    self.call3_end_date = started_at + 181.days
  end

  def closest_call_session(date)
    date = date.to_date
    closest_session = nil
    smallest_distance = Float::INFINITY

    (0..3).each do |i|
      start_date = self.send("call#{i}_start_date")
      end_date = self.send("call#{i}_end_date")

      next unless start_date.present? && end_date.present?

      distance_to_start = (date - start_date).abs
      distance_to_end = (date - end_date).abs

      closest_distance = [distance_to_start, distance_to_end].min

      if closest_distance < smallest_distance
        closest_session = i
        smallest_distance = closest_distance
      end
    end

    closest_session
  end

  def call_session_in_progress?(call_index)
    start_date = send(:"call#{call_index}_start_date")
    end_date = send(:"call#{call_index}_end_date")
    return false unless start_date.present? && end_date.present?

    Time.zone.today.between?(start_date, end_date)
  end

  ransacker :group_status, formatter: proc { |values|
    values = Array(values)
    ids = []
    ids += group_active.pluck(:id) if values.include?('active')
    ids += group_ended.pluck(:id) if values.include?('ended')
    ids += group_next.pluck(:id) if values.include?('next')
    ids.uniq.presence
  } do |group|
    group.table[:id]
  end

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail
end
