# == Schema Information
#
# Table name: support_modules
#
#  id            :bigint           not null, primary key
#  age_ranges    :string           is an Array
#  discarded_at  :datetime
#  for_bilingual :boolean          default(FALSE), not null
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
  default_scope -> { kept }

  READING = 'reading'.freeze
  SONGS = 'songs'.freeze
  BILINGUALISM = 'bilingualism'.freeze
  LANGUAGE = 'language'.freeze
  GAMES = 'games'.freeze
  SCREEN = 'screen'.freeze
  RIDE = 'ride'.freeze
  ANGER = 'anger'.freeze
  LANGUAGE_MODULE_ZERO = 'language_module_zero'.freeze

  THEME_LIST = [READING, BILINGUALISM, LANGUAGE, SONGS, GAMES, SCREEN, RIDE, ANGER].freeze
  MODULE_ZERO_THEME_LIST = [LANGUAGE_MODULE_ZERO].freeze
  THEME_LIST_INCLUDING_MODULE_ZERO = THEME_LIST + MODULE_ZERO_THEME_LIST

  LESS_THAN_FIVE = 'less_than_five'.freeze
  FIVE_TO_ELEVEN = 'five_to_eleven'.freeze
  TWELVE_TO_SEVENTEEN = 'twelve_to_seventeen'.freeze
  EIGHTEEN_TO_TWENTY_THREE = 'eighteen_to_twenty_three'.freeze
  TWENTY_FOUR_TO_TWENTY_NINE = 'twenty_four_to_twenty_nine'.freeze
  THIRTY_TO_THIRTY_FIVE = 'thirty_to_thirty_five'.freeze
  THIRTY_SIX_TO_FORTY = 'thirty_six_to_forty'.freeze
  FORTY_ONE_TO_FORTY_FOUR = 'forty_one_to_forty_four'.freeze
  FOUR_TO_TEN = 'four_to_ten'.freeze
  ELEVEN_TO_SIXTEEN = 'eleven_to_sixteen'.freeze
  SEVENTEEN_TO_TWENTY_TWO = 'seventeen_to_twenty_two'.freeze
  TWENTY_THREE_AND_MORE = 'twenty_three_and_more'.freeze
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
  MODULE_ZERO_AGE_RANGE_LIST = [
    FOUR_TO_TEN,
    ELEVEN_TO_SIXTEEN,
    SEVENTEEN_TO_TWENTY_TWO,
    TWENTY_THREE_AND_MORE
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
  validates :theme, inclusion: { in: THEME_LIST_INCLUDING_MODULE_ZERO }, allow_blank: false
  validates :level, numericality: { only_integer: true, greater_than_or_equal_to: 1 }, presence: true
  validates :age_ranges, presence: true
  validate :valid_age_ranges

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
  scope :four_to_ten, -> { where("'#{FOUR_TO_TEN}' = ANY (age_ranges)") }
  scope :eleven_to_sixteen, -> { where("'#{ELEVEN_TO_SIXTEEN}' = ANY (age_ranges)") }
  scope :seventeen_to_twenty_two, -> { where("'#{SEVENTEEN_TO_TWENTY_TWO}' = ANY (age_ranges)") }
  scope :twenty_three_and_more, -> { where("'#{TWENTY_THREE_AND_MORE}' = ANY (age_ranges)") }
  scope :level_one, -> { where(level: 1) }
  scope :with_theme_level_and_age_range, -> { where.not(theme: [nil, '']).where.not(level: nil).where('ARRAY_LENGTH(age_ranges, 1) > 0') }
  scope :by_theme, -> { order(order_by_theme) }

  # ---------------------------------------------------------------------------
  # callbacks
  # ---------------------------------------------------------------------------

  before_save do
    self.age_ranges = age_ranges&.reject(&:blank?)
  end

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

  def self.order_by_theme
    ret = 'CASE'
    THEME_LIST.each_with_index do |theme, index|
      ret << " WHEN theme = '#{theme}' THEN #{index}"
    end
    ret << ' END'
    Arel.sql(ret)
  end

  def currently_used?
    children_support_modules.any? || ChildrenSupportModule.using_support_module(id).any?
  end

  private

  def valid_age_ranges
    errors.add(:age_ranges, :invalid, message: 'doit être rempli(e)') if age_ranges.reject(&:blank?).empty?

    return if THEME_LIST.include?(theme) && (age_ranges.reject(&:blank?) - AGE_RANGE_LIST).empty?

    return if MODULE_ZERO_THEME_LIST.include?(theme) && (age_ranges.reject(&:blank?) - MODULE_ZERO_AGE_RANGE_LIST).empty?

    errors.add(:age_ranges, :invalid, message: 'ne correspond pas au thème')
  end
end
