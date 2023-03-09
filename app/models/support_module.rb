# == Schema Information
#
# Table name: support_modules
#
#  id            :bigint           not null, primary key
#  age_ranges    :string           is an Array
#  discarded_at  :datetime
#  for_bilingual :boolean
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

  THEME_LIST = %w(reading language games screen songs).freeze
  AGE_RANGE_LIST = %w(less_than_five six_to_eleven twelve_to_seventeen eighteen_to_twenty_three).freeze

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

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :less_than_five, -> { where("'less_than_five' = ANY (age_ranges)") }
  scope :six_to_eleven, -> { where("'six_to_eleven' = ANY (age_ranges)") }
  scope :twelve_to_seventeen, -> { where("'twelve_to_seventeen' = ANY (age_ranges)") }
  scope :eighteen_to_twenty_three, -> { where("'eighteen_to_twenty_three' = ANY (age_ranges)") }

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
