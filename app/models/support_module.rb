# == Schema Information
#
# Table name: support_modules
#
#  id           :bigint           not null, primary key
#  ages         :string           not null
#  discarded_at :datetime
#  name         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_support_modules_on_discarded_at  (discarded_at)
#

class SupportModule < ApplicationRecord

  include Discard::Model

  AGES = %w[
    a0_1
    a1_2
  ].freeze

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  has_many :support_module_weeks,
           -> { positioned },
           dependent: :destroy

  accepts_nested_attributes_for :support_module_weeks, allow_destroy: true

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :name, presence: true
  validates :ages,
            presence: true,
            inclusion: {
              in: AGES
            }

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail

  # ---------------------------------------------------------------------------
  # tags
  # ---------------------------------------------------------------------------

  acts_as_taggable

end
