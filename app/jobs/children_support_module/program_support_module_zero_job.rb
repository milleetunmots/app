class ChildrenSupportModule

  class ProgramSupportModuleZeroJob < ApplicationJob

    def perform(group_id, program_date)
      @errors = {}
      group = Group.find(group_id)

      less_than_five_children = group.children.months_lt(5).where(group_status: 'active')
      five_to_eleven_children = group.children.months_between(5, 12).where(group_status: 'active')
      twelve_to_seventeen_children = group.children.months_between(12, 18).where(group_status: 'active')
      eighteen_to_twenty_three_children = group.children.months_between(18, 24).where(group_status: 'active')
      twenty_four_to_twenty_nine_children = group.children.months_between(24, 30).where(group_status: 'active')
      thirty_to_thirty_five_children = group.children.months_between(30, 36).where(group_status: 'active')
      thirty_six_to_forty_children = group.children.months_between(36, 41).where(group_status: 'active')
      forty_one_to_forty_four_children = group.children.months_between(41, 45).where(group_status: 'active')

      less_than_five_support_module_zero = SupportModule.less_than_five.find_by(theme: 'language-module-zero')
      five_to_eleven_support_module_zero = SupportModule.five_to_eleven.find_by(theme: 'language-module-zero')
      twelve_to_seventeen_support_module_zero = SupportModule.twelve_to_seventeen.find_by(theme: 'language-module-zero')
      eighteen_to_twenty_three_support_module_zero = SupportModule.eighteen_to_twenty_three.find_by(theme: 'language-module-zero')
      twenty_four_to_twenty_nine_support_module_zero = SupportModule.twenty_four_to_twenty_nine.find_by(theme: 'language-module-zero')
      thirty_to_thirty_five_support_module_zero = SupportModule.thirty_to_thirty_five.find_by(theme: 'language-module-zero')
      thirty_six_to_forty_children_support_module_zero = SupportModule.thirty_six_to_forty.find_by(theme: 'language-module-zero')
      forty_one_to_forty_four_children_support_module_zero = SupportModule.forty_one_to_forty_four.find_by(theme: 'language-module-zero')

      less_than_five_children.each do |child|
        create_children_support_module(child, less_than_five_support_module_zero, child.parent1)
        create_children_support_module(child, less_than_five_support_module_zero, child.parent2)
      end

      five_to_eleven_children.each do |child|
        create_children_support_module(child, five_to_eleven_support_module_zero, child.parent1)
        create_children_support_module(child, five_to_eleven_support_module_zero, child.parent2)
      end

      twelve_to_seventeen_children.each do |child|
        create_children_support_module(child, twelve_to_seventeen_support_module_zero, child.parent1)
        create_children_support_module(child, twelve_to_seventeen_support_module_zero, child.parent2)
      end

      eighteen_to_twenty_three_children.each do |child|
        create_children_support_module(child, eighteen_to_twenty_three_support_module_zero, child.parent1)
        create_children_support_module(child, eighteen_to_twenty_three_support_module_zero, child.parent2)
      end

      twenty_four_to_twenty_nine_children.each do |child|
        create_children_support_module(child, twenty_four_to_twenty_nine_support_module_zero, child.parent1)
        create_children_support_module(child, twenty_four_to_twenty_nine_support_module_zero, child.parent2)
      end

      thirty_to_thirty_five_children.each do |child|
        create_children_support_module(child, thirty_to_thirty_five_support_module_zero, child.parent1)
        create_children_support_module(child, thirty_to_thirty_five_support_module_zero, child.parent2)
      end

      thirty_six_to_forty_children.each do |child|
        create_children_support_module(child, thirty_six_to_forty_children_support_module_zero, child.parent1)
        create_children_support_module(child, thirty_six_to_forty_children_support_module_zero, child.parent2)
      end

      forty_one_to_forty_four_children.each do |child|
        create_children_support_module(child, forty_one_to_forty_four_children_support_module_zero, child.parent1)
        create_children_support_module(child, forty_one_to_forty_four_children_support_module_zero, child.parent2)
      end

      ChildrenSupportModule::ProgramSupportModuleSmsJob.perform_later(group_id, program_date)

      if @errors.any?
        AdminUser.all_logistics_team_members.each do |admin_user|
          Task.create(
            assignee_id: admin_user.id,
            title: "Il y a eu des erreurs lors de la programmation du module 0 pour la cohorte \"#{group.name}\"",
            description: @errors.to_json,
            due_date: Date.today
          )
        end
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
