# == Schema Information
#
# Table name: child_supports
#
#  id                          :bigint           not null, primary key
#  call1_duration              :string
#  call1_language_development  :text
#  call1_notes                 :text
#  call1_parent_actions        :text
#  call1_parent_progress       :string
#  call1_status                :string
#  call1_status_details        :text
#  call2_content_usage         :text
#  call2_duration              :string
#  call2_goals                 :text
#  call2_language_development  :text
#  call2_notes                 :text
#  call2_program_investment    :string
#  call2_status                :string
#  call2_status_details        :text
#  call2_technical_information :text
#  call3_content_usage         :text
#  call3_duration              :string
#  call3_goals                 :text
#  call3_language_development  :text
#  call3_notes                 :text
#  call3_program_investment    :string
#  call3_status                :string
#  call3_status_details        :text
#  call3_technical_information :text
#  important_information       :text
#  should_be_read              :boolean
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  supporter_id                :bigint
#
# Indexes
#
#  index_child_supports_on_call1_parent_progress     (call1_parent_progress)
#  index_child_supports_on_call2_program_investment  (call2_program_investment)
#  index_child_supports_on_call3_program_investment  (call3_program_investment)
#  index_child_supports_on_should_be_read            (should_be_read)
#  index_child_supports_on_supporter_id              (supporter_id)
#
# Foreign Keys
#
#  fk_rails_...  (supporter_id => admin_users.id)
#

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

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :supporter, class_name: :AdminUser
  has_many :children,
           dependent: :nullify

  def first_child
    children.first
  end

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

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

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :supported_by, ->(model) { where(supporter: model) }

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  delegate :parent1,
           :parent2,
           :should_contact_parent1,
           :should_contact_parent2,
           to: :first_child,
           allow_nil: true

  def call1_parent_progress_index
    (call1_parent_progress || '').split('_').first&.to_i
  end
  def call2_program_investment_index
    (call2_program_investment || '').split('_').first&.to_i
  end
  def call3_program_investment_index
    (call3_program_investment || '').split('_').first&.to_i
  end

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail

end
