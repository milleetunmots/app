class ChildrenSupportModule

  class ProgramSupportModuleSmsJob < ApplicationJob

    def perform(group_id, first_message_date)
      errors = {}
      group = Group.find(group_id)

      current_children = group.children.where(group_status: 'active').map do |child|
        child.siblings.where(group: group, group_status: 'active').order(:birthdate).last
      end

      not_current_children = group.children.where(group_status: 'active').reject do |child|
        child == child.siblings.where(group: group, group_status: 'active').order(:birthdate).last
      end

      children_support_module_ids = ChildrenSupportModule.where(child_id: current_children).ids

      check_service = ChildrenSupportModule::CheckCreditsService.new(children_support_module_ids).call
      if check_service.errors.any?
        logistics_team_members = AdminUser.all_logistics_team_members
        logistics_team_members.each do |ltm|
          Task.create(
            assignee_id: ltm.id,
            title: "La programmation des sms de la cohorte \"#{group.name}\" a été annulé car il n'y a pas assez de crédits",
            description: check_service.errors.join("<br>"),
            due_date: Date.today
          )
        end
        raise check_service.errors.to_json
      end

      service = ChildSupport::ProgramChosenModulesService.new(children_support_module_ids, first_message_date).call
      errors[group.id] = service.errors if service.errors.any?

      ChildrenSupportModule.where(child_id: not_current_children).update_all(is_programmed: true, module_index: group&.support_module_programmed)
      group.support_module_programmed += 1
      group.save(validate: false)

      raise errors.to_json if errors.any?
    end
  end
end
