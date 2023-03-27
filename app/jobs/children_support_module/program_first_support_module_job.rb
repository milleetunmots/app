class ChildrenSupportModule

  class ProgramFirstSupportModuleJob < ApplicationJob

    def perform(group_id, program_date)
      @errors = {}
      group = Group.find(group_id)

      less_than_six_children = group.children.months_lt(6).where(group_status: 'active')
      six_to_eleven_children = group.children.months_between(6, 12).where(group_status: 'active')
      twelve_to_seventeen_children = group.children.months_between(12, 18).where(group_status: 'active')
      eighteen_to_twenty_three_children = group.children.months_between(18, 24).where(group_status: 'active')

      less_than_six_reading_level_one_support_module = SupportModule.less_than_six.level_one.find_by(theme: 'reading')
      six_to_eleven_reading_level_one_support_module = SupportModule.six_to_eleven.level_one.find_by(theme: 'reading')
      twelve_to_seventeen_reading_level_one_support_module = SupportModule.twelve_to_seventeen.level_one.find_by(theme: 'reading')
      eighteen_to_twenty_three_reading_level_one_support_module = SupportModule.eighteen_to_twenty_three.level_one.find_by(theme: 'reading')

      less_than_six_children.each do |child|
        create_children_support_module(child, less_than_six_reading_level_one_support_module, child.parent1)
        create_children_support_module(child, less_than_six_reading_level_one_support_module, child.parent2)
      end

      six_to_eleven_children.each do |child|
        create_children_support_module(child, six_to_eleven_reading_level_one_support_module, child.parent1)
        create_children_support_module(child, six_to_eleven_reading_level_one_support_module, child.parent2)
      end

      twelve_to_seventeen_children.each do |child|
        create_children_support_module(child, twelve_to_seventeen_reading_level_one_support_module, child.parent1)
        create_children_support_module(child, twelve_to_seventeen_reading_level_one_support_module, child.parent2)
      end

      eighteen_to_twenty_three_children.each do |child|
        create_children_support_module(child, eighteen_to_twenty_three_reading_level_one_support_module, child.parent1)
        create_children_support_module(child, eighteen_to_twenty_three_reading_level_one_support_module, child.parent2)
      end

      ChildrenSupportModule::ProgramSupportModuleSmsJob.perform_later(group_id, program_date)

      if @errors.any?
        AdminUser.all_logistics_team_members.each do |admin_user|
          Task.create(
            assignee_id: admin_user.id,
            title: "Il y a eu des erreurs lors de la programmation du premier module pour la cohorte \"#{group.name}\"",
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

      if parent_children_support_module.errors.any?
        @errors["child: #{child.id} - parent: #{parent.id}"] = parent_children_support_module.errors
      end
    end
  end
end
