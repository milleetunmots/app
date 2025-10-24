class ChildrenSupportModule

  class ProgramSupportModuleSmsJob < ApplicationJob

    attr :errors, :group

    def perform(group_id, first_message_date)
      @errors = {}
      @group = Group.find(group_id)
      children_support_module_ids = ChildrenSupportModule.not_programmed.where(child_id: current_children).ids
      # save books we will send in children support modules for modules 2+
      ChildrenSupportModule::SaveBookFromSupportModuleService.new(group_id: group_id).call if group.support_module_programmed >= 1
      program_chosen_modules(children_support_module_ids, first_message_date)
      update_children_support_module(not_current_children)
      update_group(group)
      bilingual_child_support_if_has_bilingualism_module(children_support_module_ids)
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
      Task::CreateAutomaticTaskService.new(
        title: "la programmation des sms de la cohorte \"#{group.name}\" a été annulé car il n'y a pas assez de crédits",
        description: check_service.errors.join('<br>')
      )
    end

    def program_chosen_modules(child_ids, first_message_date)
      service = ChildSupport::ProgramChosenModulesService.new(child_ids, first_message_date).call
      @errors[group.id] = service.errors if service.errors.any?
      raise @errors.to_json if @errors.any?
    end

    def update_children_support_module(children)
      ChildrenSupportModule.where(child_id: children).update(is_programmed: true)
    end

    def update_group(group)
      group.support_module_programmed += 1
      group.save(validate: false)
    end

    def bilingual_child_support_if_has_bilingualism_module(children_support_module_ids)
      # Find and update child_supports to bilingual if they have a bilingualism module chosen
      child_supports = ChildSupport.joins(:children_support_modules)
        .joins('INNER JOIN support_modules ON children_support_modules.support_module_id = support_modules.id')
        .where(children_support_modules: { id: children_support_module_ids })
        .where(support_modules: { theme: SupportModule::BILINGUALISM })
        .where.not(is_bilingual: '0_yes')
        .distinct

      child_supports.update_all(is_bilingual: '0_yes') if child_supports.any?
    end
  end
end
