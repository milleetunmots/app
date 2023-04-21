# == Schema Information
#
# Table name: support_modules
#
#  id            :bigint           not null, primary key
#  age_ranges    :string           is an Array
#  discarded_at  :datetime
#  for_bilingual :boolean
#  level         :integer
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

  THEME_LIST = %w[reading bilingualism language songs screen ride anger games].freeze

  LESS_THAN_FIVE = 'less_than_five'.freeze
  FIVE_TO_ELEVEN = 'five_to_eleven'.freeze
  TWELVE_TO_SEVENTEEN = 'twelve_to_seventeen'.freeze
  EIGHTEEN_TO_TWENTY_THREE = 'eighteen_to_twenty_three'.freeze
  TWENTY_FOUR_TO_TWENTY_NINE = 'twenty_four_to_twenty_nine'.freeze
  THIRTY_TO_THIRTY_FIVE = 'thirty_to_thirty_five'.freeze
  THIRTY_SIX_TO_FORTY = 'thirty_six_to_forty'.freeze
  FORTY_ONE_TO_FORTY_FOUR = 'forty_one_to_forty_four'.freeze
  AGE_RANGE_LIST = [
    LESS_THAN_FIVE,
    FIVE_TO_ELEVEN,
    TWELVE_TO_SEVENTEEN,
    EIGHTEEN_TO_TWENTY_THREE,
    TWENTY_FOUR_TO_TWENTY_NINE,
    THIRTY_TO_THIRTY_FIVE,
    THIRTY_SIX_TO_FORTY,
    FORTY_ONE_TO_FORTY_FOUR
  ].freeze

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
  validates :level, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :less_than_five, -> { where("'#{LESS_THAN_FIVE}' = ANY (age_ranges)") }
  scope :five_to_eleven, -> { where("'#{FIVE_TO_ELEVEN}' = ANY (age_ranges)") }
  scope :twelve_to_seventeen, -> { where("'#{TWELVE_TO_SEVENTEEN}' = ANY (age_ranges)") }
  scope :eighteen_to_twenty_three, -> { where("'#{EIGHTEEN_TO_TWENTY_THREE}' = ANY (age_ranges)") }
  scope :twenty_four_to_twenty_nine, -> { where("'#{TWENTY_FOUR_TO_TWENTY_NINE}' = ANY (age_ranges)") }
  scope :thirty_to_thirty_five, -> { where("'#{THIRTY_TO_THIRTY_FIVE}' = ANY (age_ranges)") }
  scope :thirty_six_to_forty, -> { where("'#{THIRTY_SIX_TO_FORTY}' = ANY (age_ranges)") }
  scope :forty_one_to_forty_four, -> { where("'#{FORTY_ONE_TO_FORTY_FOUR}' = ANY (age_ranges)") }
  scope :level_one, -> { where(level: 1) }

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
