class ChildrenSupportModule

  class ProgramSupportModuleZeroJob < ApplicationJob

    def perform(group_id, program_date)
      @errors = {}
      group = Group.find(group_id)

      four_to_nine_children = group.children.months_between(4, 10).where(group_status: 'active')
      ten_to_fifteen_children = group.children.months_between(10, 16).where(group_status: 'active')
      sixteen_to_twenty_three_children = group.children.months_between(16, 24).where(group_status: 'active')
      more_than_twenty_four_children = group.children.months_gteq(24).where(group_status: 'active')

      four_to_nine_support_module_zero = SupportModule.four_to_nine.find_by(theme: 'language-module-zero')
      ten_to_fifteen_support_module_zero = SupportModule.ten_to_fifteen.find_by(theme: 'language-module-zero')
      sixteen_to_twenty_three_support_module_zero = SupportModule.sixteen_to_twenty_three.find_by(theme: 'language-module-zero')
      more_than_twenty_four_support_module_zero = SupportModule.more_than_twenty_four.find_by(theme: 'language-module-zero')

      four_to_nine_children.each do |child|
        create_children_support_module(child, four_to_nine_support_module_zero, child.parent1)
        create_children_support_module(child, four_to_nine_support_module_zero, child.parent2)
      end

      ten_to_fifteen_children.each do |child|
        create_children_support_module(child, ten_to_fifteen_support_module_zero, child.parent1)
        create_children_support_module(child, ten_to_fifteen_support_module_zero, child.parent2)
      end

      sixteen_to_twenty_three_children.each do |child|
        create_children_support_module(child, sixteen_to_twenty_three_support_module_zero, child.parent1)
        create_children_support_module(child, sixteen_to_twenty_three_support_module_zero, child.parent2)
      end

      more_than_twenty_four_children.each do |child|
        create_children_support_module(child, more_than_twenty_four_support_module_zero, child.parent1)
        create_children_support_module(child, more_than_twenty_four_support_module_zero, child.parent2)
      end

      ChildrenSupportModule::ProgramSupportModuleSmsJob.perform_later(group_id, program_date)

      return unless @errors.any?

      AdminUser.all_logistics_team_members.each do |admin_user|
        Task.create(
          assignee_id: admin_user.id,
          title: "Il y a eu des erreurs lors de la programmation du module 0 pour la cohorte \"#{group.name}\"",
          description: @errors.to_json,
          due_date: Time.zone.today
        )
      end
    end

    private

    def create_children_support_module(child, support_module, parent)
      return unless parent
      return unless support_module

      parent_children_support_module = ChildrenSupportModule.create(
        child_id: child.id,
        parent_id: parent.id,
        available_support_module_list: [support_module.id],
        support_module: support_module
      )

      @errors["child: #{child.id} - parent: #{parent.id}"] = parent_children_support_module.errors if parent_children_support_module.errors.any?
    end
  end
end
