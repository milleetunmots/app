class ChildrenSupportModule

  class ProgramSupportModuleSmsJob < ApplicationJob

    attr :errors, :group

    def perform(group_id, first_message_date)
      @errors = {}
      @group = Group.find(group_id)
      children_support_module_ids = ChildrenSupportModule.where(child_id: current_children).ids
      check_credits(children_support_module_ids)
      program_chosen_modules(children_support_module_ids, first_message_date)
      update_children_support_module(not_current_children)
      update_group(group)
    end

    private

    def current_children
      @group.children.where(group_status: 'active').map do |child|
        child.siblings.where(group: @group, group_status: 'active').order(:birthdate).last
      end
    end

    def not_current_children
      @group.children.where(group_status: 'active').reject do |child|
        child == child.siblings.where(group: group, group_status: 'active').order(:birthdate).last
      end
    end

    def create_tasks(group, check_service)
      logistics_team_members = AdminUser.all_logistics_team_members
      logistics_team_members.each do |ltm|
        Task.create(
          assignee_id: ltm.id,
          title: "la programmation des sms de la cohorte \"#{group.name}\" a été annulé car il n'y a pas assez de crédits",
          description: check_service.errors.join('<br>'),
          due_date: Time.zone.today
        )
      end
    end

    def check_credits(child_ids)
      check_service = ChildrenSupportModule::CheckCreditsService.new(child_ids).call
      return unless check_service.errors.any?

      create_tasks(@group, check_service)
      raise check_service.errors.to_json
    end

    def program_chosen_modules(child_ids, first_message_date)
      service = ChildSupport::ProgramChosenModulesService.new(child_ids, first_message_date).call
      @errors[group.id] = service.errors if service.errors.any?
      raise @errors.to_json if @errors.any?
    end

    def update_children_support_module(children)
      ChildrenSupportModule.not_programmed.where(child_id: children).update(
        module_index: group.support_module_programmed + 1
      )
      ChildrenSupportModule.where(child_id: children).update(is_programmed: true)
    end

    def update_group(group)
      group.support_module_programmed += 1
      group.save(validate: false)
    end
  end
end
