# == Schema Information
#
# Table name: groups
#
#  id           :bigint           not null, primary key
#  discarded_at :datetime
#  ended_at     :date
#  name         :string
#  started_at   :date
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
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
  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :name,
    presence: true,
    uniqueness: {case_sensitive: false}

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :not_ended, -> { where("ended_at IS NULL OR ended_at > ?", Date.today) }
  scope :ended, -> { where("ended_at <= ?", Date.today) }

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  def is_ended?
    ended_at && ended_at <= Date.today
  end

  def is_not_ended?
    !is_ended?
  end

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail
end
