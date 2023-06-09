class ChildrenSupportModule

  class SelectDefaultSupportModuleJob < ApplicationJob

    def perform(group_id)
      group = Group.find(group_id)
      group.children.where(group_status: 'active').find_each do |child|
        next if child.have_siblings_on_same_group? && !child.current_child?

        child.children_support_modules.where(support_module: nil).each do |csm|
          # when there is no support_module chosen for a parent, we take the one chosen by the other parent
          # if there is no support_module chosen by the other parent, we take the first one available

          default_support_module_id = csm.available_support_module_list.reject(&:blank?).first

          the_other_parent = csm.parent == csm.child.parent1 ? csm.child.parent2 : csm.child.parent1
          if the_other_parent.present?
            the_other_parent_csm = the_other_parent.children_support_modules.latest_first.first

            already_done_support_module_ids = child.children_support_modules.where(parent: csm.parent).pluck(:support_module_id)
            if the_other_parent_csm.support_module_id.present? && !already_done_support_module_ids.include?(the_other_parent_csm.support_module_id)
              default_support_module_id = the_other_parent_csm.support_module_id
            end
          end

          csm.update(support_module_id: default_support_module_id)
        end
      end
    end
  end
end
