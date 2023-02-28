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

  THEME_LIST = %w(reading conversation games screen songs language).freeze
  AGE_RANGE_LIST = %w(less_than_five six_to_eleven twelve_to_seventeen eighteen_to_twenty_three).freeze

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  has_many :support_module_weeks, -> { positioned }, inverse_of: :support_module, dependent: :destroy

  accepts_nested_attributes_for :support_module_weeks, allow_destroy: true

  has_one_attached :picture

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :name, presence: true

  validates :theme, inclusion: { in: THEME_LIST, allow_blank: true }

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
