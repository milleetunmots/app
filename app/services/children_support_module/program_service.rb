class ChildrenSupportModule

  class ProgramService

    def call(group_id, program_date, age_ranges, theme)
      @errors = {}
      group = Group.find(group_id)
      module_number = group.support_module_programmed
      create_group_children_support_module(group, age_ranges, theme)
      ChildrenSupportModule::ProgramSupportModuleSmsJob.perform_later(group_id, program_date)
      return unless @errors.any?

      AdminUser.all_logistics_team_members.each do |admin_user|
        Task.create(
          assignee_id: admin_user.id,
          title: "Il y a eu des erreurs lors de la programmation du module #{module_number} pour la cohorte \"#{group.name}\"",
          description: @errors.to_json,
          due_date: Time.zone.today
        )
      end
      Rollbar.error(@errors.to_json)
    end

    private

    def create_group_children_support_module(group, ages_ranges, theme)
      ages_ranges.each do |ages_range|
        children = group.children.send(ages_range)
        support_module = SupportModule.send(ages_range).level_one.find_by(theme: theme)
        create_ages_range_children_support_module(children, support_module)
      end
    end

    def create_ages_range_children_support_module(ages_range_children, ages_range_support_module)
      ages_range_children.each do |child|
        create_children_support_module(child, ages_range_support_module, child.parent1)
        create_children_support_module(child, ages_range_support_module, child.parent2)
      end
    end

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
