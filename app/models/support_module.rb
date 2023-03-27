# == Schema Information
#
# Table name: support_modules
#
#  id            :bigint           not null, primary key
#  age_ranges    :string           is an Array
#  discarded_at  :datetime
#  for_bilingual :boolean
#  level         :string
#  name          :string
#  start_at      :date
#  theme         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_support_modules_on_age_ranges    (age_ranges) USING gin
#  index_support_modules_on_discarded_at  (discarded_at)
#

class SupportModule < ApplicationRecord

  include Discard::Model

  LESS_THAN_SIX = 'less_than_six'.freeze
  SIX_TO_ELEVEN = 'six_to_eleven'.freeze
  TWELVE_TO_SEVENTEEN = 'twelve_to_seventeen'.freeze
  EIGHTEEN_TO_TWENTY_THREE = 'eighteen_to_twenty_three'.freeze
  LEVEL_ONE = 'Niveau 1'.freeze
  LEVEL_TWO = 'Niveau 2'.freeze
  LEVEL_THREE = 'Niveau 3'.freeze
  THEME_LIST = %w[reading language games screen songs].freeze
  AGE_RANGE_LIST = [LESS_THAN_SIX, SIX_TO_ELEVEN, TWELVE_TO_SEVENTEEN, EIGHTEEN_TO_TWENTY_THREE].freeze
  LEVEL_LIST = [LEVEL_ONE, LEVEL_TWO, LEVEL_THREE].freeze

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  has_many :support_module_weeks, -> { positioned }, inverse_of: :support_module, dependent: :destroy
  has_many :children_support_modules, dependent: :nullify
  accepts_nested_attributes_for :support_module_weeks, allow_destroy: true
  has_one_attached :picture

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :name, presence: true
  validates :theme, inclusion: { in: THEME_LIST, allow_blank: true }
  validates :level, inclusion: { in: LEVEL_LIST, allow_blank: true }

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :less_than_six, -> { where("'#{LESS_THAN_SIX}' = ANY (age_ranges)") }
  scope :six_to_eleven, -> { where("'#{SIX_TO_ELEVEN}' = ANY (age_ranges)") }
  scope :twelve_to_seventeen, -> { where("'#{TWELVE_TO_SEVENTEEN}' = ANY (age_ranges)") }
  scope :eighteen_to_twenty_three, -> { where("'#{EIGHTEEN_TO_TWENTY_THREE}' = ANY (age_ranges)") }
  scope :level_one, -> { where("level = '#{LEVEL_ONE}'") }
  scope :level_two, -> { where("level = '#{LEVEL_TWO}'") }
  scope :level_three, -> { where("level = '#{LEVEL_THREE}'") }

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  def duplicate
    self.class.new(
      name: "Copie de #{name}",
      tag_list: tag_list,
      support_module_weeks: support_module_weeks.map do |smw|
        smw.class.new(
          medium: smw.medium,
          position: smw.position
        )
      end
    )
  end

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail

  # ---------------------------------------------------------------------------
  # tags
  # ---------------------------------------------------------------------------

  acts_as_taggable
end
