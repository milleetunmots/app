# == Schema Information
#
# Table name: families
#
#  id               :bigint           not null, primary key
#  discarded_at     :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  child_support_id :bigint
#  parent1_id       :bigint           not null
#  parent2_id       :bigint
#
# Indexes
#
#  index_families_on_child_support_id  (child_support_id)
#  index_families_on_parent1_id        (parent1_id)
#  index_families_on_parent2_id        (parent2_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent1_id => parents.id)
#  fk_rails_...  (parent2_id => parents.id)
#
class Family < ApplicationRecord

  belongs_to :parent1, class_name: :Parent
  belongs_to :parent2, class_name: :Parent, optional: true
  belongs_to :child_support, optional: true
  has_many :children

  accepts_nested_attributes_for :parent1
  accepts_nested_attributes_for :parent2
  accepts_nested_attributes_for :child_support

  acts_as_taggable
end
