class ChildrenSupportModule

  class ProgramFirstSupportModuleJob < ApplicationJob

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

      less_than_five_reading_level_one_support_module = SupportModule.less_than_five.level_one.find_by(theme: 'reading')
      five_to_eleven_reading_level_one_support_module = SupportModule.five_to_eleven.level_one.find_by(theme: 'reading')
      twelve_to_seventeen_reading_level_one_support_module = SupportModule.twelve_to_seventeen.level_one.find_by(theme: 'reading')
      eighteen_to_twenty_three_reading_level_one_support_module = SupportModule.eighteen_to_twenty_three.level_one.find_by(theme: 'reading')
      twenty_four_to_twenty_nine_reading_level_one_support_module = SupportModule.twenty_four_to_twenty_nine.level_one.find_by(theme: 'reading')
      thirty_to_thirty_five_reading_level_one_support_module = SupportModule.thirty_to_thirty_five.level_one.find_by(theme: 'reading')
      thirty_six_to_forty_children_reading_level_one_support_module = SupportModule.thirty_six_to_forty.level_one.find_by(theme: 'reading')
      forty_one_to_forty_four_children_reading_level_one_support_module = SupportModule.forty_one_to_forty_four.level_one.find_by(theme: 'reading')

      less_than_five_children.each do |child|
        create_children_support_module(child, less_than_five_reading_level_one_support_module, child.parent1)
        create_children_support_module(child, less_than_five_reading_level_one_support_module, child.parent2)
      end

      five_to_eleven_children.each do |child|
        create_children_support_module(child, five_to_eleven_reading_level_one_support_module, child.parent1)
        create_children_support_module(child, five_to_eleven_reading_level_one_support_module, child.parent2)
      end

      twelve_to_seventeen_children.each do |child|
        create_children_support_module(child, twelve_to_seventeen_reading_level_one_support_module, child.parent1)
        create_children_support_module(child, twelve_to_seventeen_reading_level_one_support_module, child.parent2)
      end

      eighteen_to_twenty_three_children.each do |child|
        create_children_support_module(child, eighteen_to_twenty_three_reading_level_one_support_module, child.parent1)
        create_children_support_module(child, eighteen_to_twenty_three_reading_level_one_support_module, child.parent2)
      end

      twenty_four_to_twenty_nine_children.each do |child|
        create_children_support_module(child, twenty_four_to_twenty_nine_reading_level_one_support_module, child.parent1)
        create_children_support_module(child, twenty_four_to_twenty_nine_reading_level_one_support_module, child.parent2)
      end

      thirty_to_thirty_five_children.each do |child|
        create_children_support_module(child, thirty_to_thirty_five_reading_level_one_support_module, child.parent1)
        create_children_support_module(child, thirty_to_thirty_five_reading_level_one_support_module, child.parent2)
      end

      thirty_six_to_forty_children.each do |child|
        create_children_support_module(child, thirty_six_to_forty_children_reading_level_one_support_module, child.parent1)
        create_children_support_module(child, thirty_six_to_forty_children_reading_level_one_support_module, child.parent2)
      end

      forty_one_to_forty_four_children.each do |child|
        create_children_support_module(child, forty_one_to_forty_four_children_reading_level_one_support_module, child.parent1)
        create_children_support_module(child, forty_one_to_forty_four_children_reading_level_one_support_module, child.parent2)
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
