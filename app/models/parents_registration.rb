# == Schema Information
#
# Table name: parents_registrations
#
#  id                   :bigint           not null, primary key
#  parent1_phone_number :string           not null
#  parent2_phone_number :string
#  target_profile       :boolean          default(TRUE), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  parent1_id           :bigint
#  parent2_id           :bigint
#
# Indexes
#
#  index_parents_registrations_on_parent1_id  (parent1_id)
#  index_parents_registrations_on_parent2_id  (parent2_id)
#
class ParentsRegistration < ApplicationRecord

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :parent1, class_name: 'Parent'
  belongs_to :parent2, class_name: 'Parent', optional: true

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :parent1_phone_number, presence: true

end
