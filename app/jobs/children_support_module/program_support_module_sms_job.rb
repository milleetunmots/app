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

    def active_children
      @active_children ||= @group.children.where(group_status: 'active').to_a
    end

    # Même ordre canonique que ChildSupport#current_child : sans le départageur
    # porté par Child::CURRENT_CHILD_ORDER, deux jumeaux pouvaient être désignés
    # ici et dans le reste de la chaîne d'attribution comme deux enfants différents.
    def current_children
      @current_children ||= active_children.filter_map { |child| current_sibling_for(child) }.uniq
    end

    # Partition stricte : tout enfant actif est soit courant, soit non courant.
    def not_current_children
      active_children - current_children
    end

    # Mémoïsé par fiche de suivi : c'est la population sur laquelle la désignation
    # porte, donc tous les enfants d'une même fiche donnent le même résultat.
    # `key?` plutôt que `||=` : une fiche sans enfant courant dans la cohorte
    # rejouerait sinon la requête pour chacun de ses enfants.
    def current_sibling_for(child)
      @current_sibling_by_child_support ||= {}
      return @current_sibling_by_child_support[child.child_support_id] if @current_sibling_by_child_support.key?(child.child_support_id)

      @current_sibling_by_child_support[child.child_support_id] = child.current_sibling_in_group(@group)
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
