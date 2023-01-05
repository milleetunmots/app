# == Schema Information
#
# Table name: children_support_modules
#
#  id                            :bigint           not null, primary key
#  available_support_module_list :string           is an Array
#  choice_date                   :date
#  is_completed                  :boolean          default(FALSE)
#  is_programmed                 :boolean          default(FALSE), not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  child_id                      :bigint
#  parent_id                     :bigint
#  support_module_id             :bigint
#
# Indexes
#
#  index_children_support_modules_on_child_id           (child_id)
#  index_children_support_modules_on_parent_id          (parent_id)
#  index_children_support_modules_on_support_module_id  (support_module_id)
#
class ChildrenSupportModule < ApplicationRecord

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :child
  belongs_to :parent
  belongs_to :support_module, optional: true

  scope :not_programmed, -> { where(is_programmed: false) }
  scope :programmed, -> { where(is_programmed: true) }
  scope :with_support_module, -> { joins(:support_module) }
  scope :with_the_choice_to_make_by_us, -> { where(support_module: nil).where(is_completed: true) }
  scope :without_choice, -> { where(support_module: nil).where(is_completed: false) }

  def available_support_modules
    SupportModule.where(id: available_support_module_list)
  end

  def name
    return support_module.name if support_module
    return "Laisse le choix à 1001mots" if is_completed

    "Pas encore choisi"
  end

  def support_module_collection
    SupportModule.where(id: available_support_module_list).map(&:decorate)
  end
end
