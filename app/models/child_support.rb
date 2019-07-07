class ChildSupport < ApplicationRecord

  PARENT_PROGRESS = %w[
    1_low
    2_medium
    3_high
  ].freeze
  PROGRAM_INVESTMENT = %w[
    1_low
    2_medium
    3_high
  ].freeze

  has_many :children

  validates :call1_parent_progress,
            inclusion: {
              in: PARENT_PROGRESS,
              allow_blank: true
            }
  validates :call2_program_investment,
            inclusion: {
              in: PROGRAM_INVESTMENT,
              allow_blank: true
            }
  validates :call3_program_investment,
            inclusion: {
              in: PROGRAM_INVESTMENT,
              allow_blank: true
            }

  def first_child
    children.first
  end

  delegate :parent1,
           :parent2,
           :should_contact_parent1,
           :should_contact_parent2,
           to: :first_child

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail

end
