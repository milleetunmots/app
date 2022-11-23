# == Schema Information
#
# Table name: children_support_modules
#
#  id                            :bigint           not null, primary key
#  available_support_module_list :string           is an Array
#  choice_date                   :date
#  is_completed                  :boolean          default(FALSE)
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

  def available_support_modules
    SupportModule.where(id: available_support_module_list)
  end

  def name
    return unless support_module

    support_module&.name
  end

end
