# == Schema Information
#
# Table name: groups
#
#  id                        :bigint           not null, primary key
#  discarded_at              :datetime
#  ended_at                  :date
#  expected_children_number  :integer
#  is_programmed             :boolean          default(FALSE), not null
#  name                      :string
#  started_at                :date
#  support_module_programmed :integer          default(0)
#  support_modules_count     :integer          default(0), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  index_groups_on_discarded_at  (discarded_at)
#  index_groups_on_ended_at      (ended_at)
#  index_groups_on_started_at    (started_at)
#

class Group < ApplicationRecord

  include Discard::Model

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
  validates :started_at, presence: true, on: :create
  validate :started_at_only_monday

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :not_ended, -> { where('ended_at IS NULL OR ended_at > ?', Time.zone.today) }
  scope :ended, -> { where('ended_at <= ?', Time.zone.today) }
  scope :not_started, -> { where('started_at >= ? AND support_module_programmed = ?', Time.zone.today, 0) }
  scope :started, -> { where('started_at < ? OR support_module_programmed > ?', Time.zone.today, 0) }

  # ---------------------------------------------------------------------------
  # callbacks
  # ---------------------------------------------------------------------------

  before_create :standardize_name
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
    children.joins(:child_support).where(child_supports: { is_bilingual: true })
  end

  def with_module_zero?
    started_at >= DateTime.parse(ENV['MODULE_ZERO_FEATURE_START'])
  end

  def add_waiting_children
    # Add waiting children to next available group for them (could be another group)
    Child::AddWaitingChildrenToGroupJob.perform_later
  end

  def standardize_name
    if expected_children_number&.positive?
      last_group = Group.where.not(started_at: nil).where('expected_children_number > ?', 0).where('extract(month from started_at) = ? AND extract(year from started_at) = ?', started_at.month, started_at.year).order(:started_at).last
      index = last_group.present? ? last_group.name.split('-').last.to_i + 1 : 1
      self.name = "#{started_at.strftime('%Y/%m/%d')} - #{I18n.t started_at.strftime('%B')}#{started_at.strftime('%y')} - #{index}"
    else
      self.name = "#{started_at.strftime('%Y/%m/%d')} - #{self.name}"
    end
  end

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail
end
