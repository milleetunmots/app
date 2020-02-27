# == Schema Information
#
# Table name: child_supports
#
#  id                              :bigint           not null, primary key
#  book_not_received               :string
#  call1_books_quantity            :integer
#  call1_duration                  :integer
#  call1_language_development      :text
#  call1_notes                     :text
#  call1_parent_actions            :text
#  call1_parent_progress           :string
#  call1_reading_frequency         :string
#  call1_status                    :string
#  call1_status_details            :text
#  call2_content_usage             :text
#  call2_duration                  :integer
#  call2_goals                     :text
#  call2_language_awareness        :string
#  call2_language_development      :text
#  call2_notes                     :text
#  call2_parent_progress           :string
#  call2_program_investment        :string
#  call2_status                    :string
#  call2_status_details            :text
#  call2_technical_information     :text
#  call3_content_usage             :text
#  call3_duration                  :integer
#  call3_goals                     :text
#  call3_language_awareness        :string
#  call3_language_development      :text
#  call3_notes                     :text
#  call3_parent_progress           :string
#  call3_sendings_benefits         :string
#  call3_sendings_benefits_details :text
#  call3_status                    :string
#  call3_status_details            :text
#  call3_technical_information     :text
#  important_information           :text
#  is_bilingual                    :boolean
#  second_language                 :string
#  should_be_read                  :boolean
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  supporter_id                    :bigint
#
# Indexes
#
#  index_child_supports_on_book_not_received         (book_not_received)
#  index_child_supports_on_call1_parent_progress     (call1_parent_progress)
#  index_child_supports_on_call1_reading_frequency   (call1_reading_frequency)
#  index_child_supports_on_call2_language_awareness  (call2_language_awareness)
#  index_child_supports_on_call2_parent_progress     (call2_parent_progress)
#  index_child_supports_on_call2_program_investment  (call2_program_investment)
#  index_child_supports_on_call3_language_awareness  (call3_language_awareness)
#  index_child_supports_on_call3_parent_progress     (call3_parent_progress)
#  index_child_supports_on_should_be_read            (should_be_read)
#  index_child_supports_on_supporter_id              (supporter_id)
#
# Foreign Keys
#
#  fk_rails_...  (supporter_id => admin_users.id)
#

class ChildSupport < ApplicationRecord

  LANGUAGE_AWARENESS = %w[
    1_none
    2_awareness
  ].freeze
  PARENT_PROGRESS = %w[
    1_low
    2_medium
    3_high
    4_excellent
  ].freeze
  PROGRAM_INVESTMENT = %w[
    1_low
    2_medium
    3_high
  ].freeze
  READING_FREQUENCY = %w[
    1_rarely
    2_weekly
    3_frequently
    4_daily
  ].freeze
  SENDINGS_BENEFITS = %w[
    1_none
    2_far
    3_remind
    4_frequent
    5_frequent_helps
  ].freeze

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :supporter,
             class_name: :AdminUser,
             optional: true
  has_many :children,
           dependent: :nullify
  has_one :first_child, class_name: :Child
  has_one :parent1, through: :first_child
  has_one :parent2, through: :first_child

  accepts_nested_attributes_for :first_child

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :call1_parent_progress,
            inclusion: {
              in: PARENT_PROGRESS,
              allow_blank: true
            }
  validates :call2_language_awareness,
            inclusion: {
              in: LANGUAGE_AWARENESS,
              allow_blank: true
            }
  validates :call2_parent_progress,
            inclusion: {
              in: PARENT_PROGRESS,
              allow_blank: true
            }
  validates :call2_program_investment,
            inclusion: {
              in: PROGRAM_INVESTMENT,
              allow_blank: true
            }
  validates :call3_language_awareness,
            inclusion: {
              in: LANGUAGE_AWARENESS,
              allow_blank: true
            }
  validates :call3_parent_progress,
            inclusion: {
              in: PARENT_PROGRESS,
              allow_blank: true
            }
  validates :call3_sendings_benefits,
            inclusion: {
              in: SENDINGS_BENEFITS,
              allow_blank: true
            }

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :supported_by, ->(model) { where(supporter: model) }

  def self.call1_parent_progress_present(bool)
    if bool
      where(call1_parent_progress: PARENT_PROGRESS)
    else
      where.not(call1_parent_progress: PARENT_PROGRESS)
    end
  end

  def self.call2_program_investment_present(bool)
    if bool
      where(call2_program_investment: PROGRAM_INVESTMENT)
    else
      where.not(call2_program_investment: PROGRAM_INVESTMENT)
    end
  end

  def self.call3_sendings_benefits_present(bool)
    if bool
      where(call3_sendings_benefits: PROGRAM_INVESTMENT)
    else
      where.not(call3_sendings_benefits: PROGRAM_INVESTMENT)
    end
  end

  def self.groups_in(*v)
    where(id: Child.where(group_id: v).select('DISTINCT child_support_id'))
  end

  def self.registration_sources_in(*v)
    where(id: Child.where(registration_source: v).select('DISTINCT child_support_id'))
  end

  scope :with_book_not_received, -> { where.not(book_not_received: [nil, '']) }

  # ---------------------------------------------------------------------------
  # ransack
  # ---------------------------------------------------------------------------

  def self.ransackable_scopes(auth_object = nil)
    %i(groups_in registration_sources_in)
  end

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  delegate :address,
           :city_name,
           :letterbox_name,
           :parent_events,
           :parent1_first_name,
           :parent1_gender,
           :parent1_is_ambassador,
           :parent1_is_ambassador?,
           :parent1_is_lycamobile,
           :parent1_is_lycamobile?,
           :parent1_last_name,
           :parent1_phone_number_national,
           :parent2_first_name,
           :parent2_gender,
           :parent2_is_ambassador,
           :parent2_is_ambassador?,
           :parent2_is_lycamobile,
           :parent2_is_lycamobile?,
           :parent2_last_name,
           :parent2_phone_number_national,
           :postal_code,
           :should_contact_parent1,
           :should_contact_parent1?,
           :should_contact_parent2,
           :should_contact_parent2?,
           to: :first_child,
           allow_nil: true

  delegate :name,
           to: :supporter,
           prefix: true,
           allow_nil: true

  def call1_parent_progress_index
    (call1_parent_progress || '').split('_').first&.to_i
  end
  def call2_parent_progress_index
    (call2_parent_progress || '').split('_').first&.to_i
  end
  def call3_parent_progress_index
    (call3_parent_progress || '').split('_').first&.to_i
  end

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail

end
