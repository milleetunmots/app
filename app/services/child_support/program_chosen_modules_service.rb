class ChildSupport

  class ProgramChosenModulesService

    attr_reader :errors

    def initialize(ids, date)
      @chosen_modules = ChildrenSupportModule.includes(:parent, child: :child_support).with_support_module.not_programmed.where(id: ids)
      @first_message_date = date
      @errors = []
    end

    def call
      program_chosen_modules
      clean_support_module_list
      self
    end

    private

    def check_group(group)
      return if group

      @errors << 'Cohorte introuvable'
      raise @errors.join('\n')
    end

    def program_chosen_modules
      @chosen_modules.group_by(&:support_module_id).each do |support_module_id, children_support_modules|
        group = @chosen_modules.first.child.group
        check_group(group)
        program_support_module(children_support_modules, group)
        update_children_support_module(children_support_modules, group)
        # to avoid sending to many api calls to spot-hit, sleep 60 seconds between each module
        # sleep(60)
      rescue StandardError => e
        support_module = SupportModule.find(support_module_id)
        parent_names = children_support_modules.map { |csm| csm.parent.decorate.name }.join(', ')
        @errors << "
          Erreur en programmant le module #{support_module.name} pour les parents suivant: #{parent_names}.\n
          Il est possible qu'une partie des messages ai été programmé. Erreur technique : #{e.message}.
        "
      end
    end

    def program_support_module(support_modules, group)
      service = SupportModule::ProgramService.new(
        support_modules,
        @first_message_date,
        recipients: support_modules.map { |csm| "parent.#{csm.parent_id}" },
        first_support_module: group.support_module_programmed.zero?
      ).call

      raise service.errors.join("\n") if service.errors.any?
    end

    def update_children_support_module(csm, group)
      # support_module_programmed has not been incremented yet at this moment
      # so we add +1 to the current count. It will be incremented after this service in ProgramSupportModuleSmsJob
      # if there is no error
      ChildrenSupportModule.where(id: csm.map(&:id)).update(
        is_programmed: true,
        module_index: group.support_module_programmed + 1
      )
    end

    def clean_support_module_list
      @chosen_modules.each do |csm|
        csm.child.child_support&.update(parent1_available_support_module_list: [], parent2_available_support_module_list: [])
      end
    end
  end
end
