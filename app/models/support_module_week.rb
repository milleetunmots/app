# == Schema Information
#
# Table name: support_module_weeks
#
#  id                   :bigint           not null, primary key
#  has_been_sent1       :boolean          default(FALSE), not null
#  has_been_sent2       :boolean          default(FALSE), not null
#  has_been_sent3       :boolean          default(FALSE), not null
#  has_been_sent4       :boolean          default(FALSE), not null
#  position             :integer          default(0), not null
#  additional_medium_id :integer
#  medium_id            :bigint
#  support_module_id    :bigint           not null
#
# Indexes
#
#  index_support_module_weeks_on_additional_medium_id  (additional_medium_id)
#  index_support_module_weeks_on_medium_id             (medium_id)
#  index_support_module_weeks_on_position              (position)
#  index_support_module_weeks_on_support_module_id     (support_module_id)
#
# Foreign Keys
#
#  fk_rails_...  (additional_medium_id => media.id)
#

class SupportModuleWeek < ApplicationRecord

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :support_module
  belongs_to :medium, optional: true
  belongs_to :additional_medium, class_name: :Medium, optional: true

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :position,
            presence: true

  # ---------------------------------------------------------------------------
  # SCOPES
  # ---------------------------------------------------------------------------

  def self.positioned
    order(:position)
  end

end
