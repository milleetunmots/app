class ChildrenSupportModule

  class SelectDefaultSupportModuleJob < ApplicationJob

    def perform(group_id)
      group = Group.find(group_id)
      group.children.where(group_status: 'active').find_each do |child|
        child.children_support_modules.where(support_module: nil).each do |csm|
          the_other_parent = csm.parent == csm.child.parent1 ? csm.child.parent2 : csm.child.parent1
          if the_other_parent.children_support_modules.where.not(support_module: nil).count > csm.parent.children_support_modules.where.not(support_module: nil).count
            csm.update(support_module_id: the_other_parent.children_support_modules.last.support_module.id)
          else
            first_support_module_id = csm.available_support_module_list.reject(&:blank?).first
            csm.update(support_module_id: first_support_module_id)
          end
        end
      end
    end
  end
end
